function [SINEX] = readSNX(filename, varargin)
%  script to parse SNX file
%
% Alexandr Sokolov, KEG
% 11.10.2016
% 

if ~isempty(varargin)
    flag = varargin{:}; 
    flag
end

tic

% check if file exist
filename
fullpath = filename
if exist(fullpath, 'file') ~= 2
    disp(['ERROR, File not found: ',fullpath])
else

%% Blocks in SINEX file , Dummy

SOLUTION = struct('STATISTICS', [], ...
                  'EPOCHS', [], ...
                  'ESTIMATE', [], ...
                  'APRIORI', [], ...
                  'COVA_ESTIMATE', [], ...
                  'COVA_APRIORI', []);
              
SITE     = struct('ID', [], ...
                  'RECEIVER', [], ...
                  'ANTENNA', [], ...
                  'GPS_PHASE_CENTER', [], ...
                  'ECCENTRICITY', []);

%%

% copy part of file into separate
disp([' ... Parsing ', filename, ' ...']);

% DataTypes used as Search pattern
DataType = {'FILE/REFERENCE';
            'INPUT/ACKNOWLEDGMENTS';
            'SOLUTION/STATISTICS';
            'SITE/ID';
            'SITE/RECEIVER';
            'SITE/ANTENNA';
            'SITE/GPS_PHASE_CENTER';
            'SITE/ECCENTRICITY';
            'SOLUTION/EPOCHS';
            'SOLUTION/ESTIMATE';
            'SOLUTION/APRIORI';
            'SOLUTION/MATRIX_ESTIMATE L COVA';
            'SOLUTION/MATRIX_APRIORI L COVA'};
        
%% look for available DataTypes block in SNX file
% filename = 'EPN_A_IGb08_no_COVA.SNX';
% fullpath = which(filename);

disp(['grep +[A-Z] ', fullpath, ' ']);
comm = ['grep +[A-Z] ', fullpath, ' | awk ', '''' ,'{if( substr($1,1,1) == "+") print}', '''' ,' |  cut --characters 2-']
[status, msgout]= system(comm, '-echo');
DataTypeAvailable = strsplit(msgout,'\n')';
range = 1:length(DataType);
iiBlockAvailable = range(ismember(DataType, DataTypeAvailable));
iiBlocksToBeParse = iiBlockAvailable;

%% check flag and add COVA

if ismember(flag, {'All', 'all', 'cov','with covariance', 'COVA'})
   if ismember(DataType, 'SOLUTION/MATRIX_ESTIMATE L COVA');
      iiBlocksToBeParse = [iiBlocksToBeParse, 12]; 
   end
   if ismember(DataType, 'SOLUTION/MATRIX_APRIORI L COVA');
      iiBlocksToBeParse = [iiBlocksToBeParse, 13]; 
   end
end

%% check flag and exclude COVA

if ismember(flag, {'noCov', 'nocov'})
  iiBlocksToBeParse = setdiff(iiBlocksToBeParse, [12, 13]); 
end

%% Parsing
iiBlocksToBeParse
for iData = [iiBlocksToBeParse]
    [status, StartEndLines]= system(['grep --line-number "',DataType{iData},'" ', fullpath,' | cut -f1 -d:']);
    if (status ~= 0) % 0 = successful
        disp(['Error: status :', numn2str(status)]);
    end
    
    StartEndLine = str2num(StartEndLines(1,:));
    StartLine = StartEndLine(1);
    EndLine = StartEndLine(2);
    Len = EndLine - StartLine + 1;
    tmpFile = 'tmp.txt';
    
    %disp(                     ['tail -n +', num2str(StartLine), ' "', fullpath,'" | head -',num2str(Len),' > ', tmpFile ])
    [status, cmdout] = system(['tail -n +', num2str(StartLine), ' "', fullpath,'" | head -',num2str(Len),' > ', tmpFile ]);
    %disp(['status: ', num2str(status), ' ; cmdout: ',cmdout]);
    
    if exist(tmpFile, 'file') ~= 2
       disp('Error: tmp file is not written!') 
    else
    
    % ------ parse statistics ------------
     if iData == 3  % 'SOLUTION/STATISTICS'
        fileID = fopen(tmpFile);
        disp(fgetl(fileID));
        disp(fgetl(fileID)); 
        line = fgetl(fileID);
        ObsNum = str2double(line(33:54));
        line = fgetl(fileID);
        UnknNum = str2double(line(33:54));
        line = fgetl(fileID);
        DoFNum = str2double(line(33:54));
        line = fgetl(fileID);
        PhaseSigma = str2double(line(33:54));
        line = fgetl(fileID);
        Sampling = str2double(line(33:54));
        line = fgetl(fileID);
        VarianceFactor = str2double(line(33:54));
        disp(fgetl(fileID));
        fclose(fileID);
        STATISTICS = struct('ObsNum', ObsNum, ...
                            'UnknNum',UnknNum, ...
                            'DoFNum', DoFNum, ...
                            'PhaseSigma', PhaseSigma, ...
                            'Sampling', Sampling, ...
                            'VarianceFactor', VarianceFactor);    
        SOLUTION.STATISTICS = STATISTICS;
     end
    % ------ parsing of statintics end ---
    
    % ------ parse site id --------------- ok
     if iData == 4  % 'SITE/ID'
        fileID = fopen(tmpFile);
        disp(fgetl(fileID));
        disp(fgetl(fileID)); 
        SiteName    = repmat(char(0),Len-3,4);
        PT          = repmat(char(0),Len-3,1);
        DOMES       = repmat(char(0),Len-3,9);
        T           = repmat(char(0),Len-3,20);
        DESCRIPTION = repmat(char(0),Len-3,22);
        Lon = zeros(Len-3,1);
        Lat = zeros(Len-3,1);
        H   = zeros(Len-3,1);
        for iRow = 1:Len-3
            line = fgetl(fileID);
            SiteName(iRow,:) = line(2:5);
            PT(iRow,1) = line(8);
            DOMES(iRow,:) = line(10:18);
            T(iRow,1) = line(20);
            DESCRIPTION(iRow,:) = line(22:43);
            Lon_d = str2double(line(45:47));
            Lon_m = str2double(line(49:50));
            Lon_s = str2double(line(52:56));
            Lon(iRow,1) = dms2degrees([Lon_d, Lon_m, Lon_s]);
            Lat_d = str2double(line(58:59));
            Lat_m = str2double(line(61:62));
            Lat_s = str2double(line(64:67));
            Lat(iRow,1) = dms2degrees([Lat_d, Lat_m, Lat_s]);
            H(iRow,1) = str2double(line(69:end));       
        end
        disp(fgetl(fileID));
        fclose(fileID);
        ID = struct('CODE',SiteName,'PT',PT,'DOMES',DOMES,'T',T, ...
            'DESCRIPTION',DESCRIPTION,'LAT',Lat,'LON',Lon,'H',H);
        SITE.ID = ID;
     end
    % ------ parsing of site id end ------
    
    % ------ parsing Receiver ------------
     if iData == 5  % 'SITE/RECEIVER'
        SiteName    = repmat(char(0),Len-3,4);
        PT          = repmat(char(0),Len-3,1);
        SolN        = zeros(Len-3,1);
        T           = repmat(char(0),Len-3,1);
        DATA_START  = repmat(char(0),Len-3,12);
        DATA_END    = repmat(char(0),Len-3,12);
        Receiver    = repmat(char(0),Len-3,20);
        SN          = repmat(char(0),Len-3,5);
        Firmware    = repmat(char(0),Len-3,11);
        fileID = fopen(tmpFile);
        disp(fgetl(fileID));
        disp(fgetl(fileID)); 
        for iRow = 1:Len-3
            line = fgetl(fileID);
            SiteName(iRow,:) = line(2:5);
            PT(iRow,1) = line(8);
            SolNumber = line(10:13);
            if strcmp(SolNumber, '----')
                SolN(iRow,1) = iRow;
            else
                SolN(iRow,1) = str2num(SolNumber);
            end
            T(iRow,1) = line(15);
            DATA_START(iRow,:) = line(17:28);
            DATA_END(iRow,:)   = line(30:41);
            Receiver(iRow,:)   = line(43:62);
            SN(iRow,:) = line(64:68);
            FW = line(70:length(line));
            Firmware(iRow,1:length(FW)) = FW;
        end
        disp(fgetl(fileID));
        fclose(fileID);
        RECEIVER = struct('CODE',SiteName,'PT',PT,'SolN',SolN,'T',T, ...
            'DATA_START',DATA_START,'DATA_END',DATA_END, ...
            'Receiver',Receiver,'SN',SN,'Firmware',Firmware);
        SITE.RECEIVER = RECEIVER;
        end
    % ----- parsing reseiver end ---------

    % ------ parsing Antenna ------------
     if iData == 6  % 'SITE/ANTENNA'
        SiteName    = repmat(char(0),Len-3,4);
        PT          = repmat(char(0),Len-3,1);
        SolN        = zeros(Len-3,1);
        T           = repmat(char(0),Len-3,1);
        DATA_START  = repmat(char(0),Len-3,12);
        DATA_END    = repmat(char(0),Len-3,12);
        Antenna     = repmat(char(0),Len-3,20);
        SN          = repmat(char(0),Len-3,5);
        fileID = fopen(tmpFile);
        disp(fgetl(fileID));
        disp(fgetl(fileID)); 
        for iRow = 1:Len-3
            line = fgetl(fileID);
            SiteName(iRow,:) = line(2:5);
            PT(iRow,1) = line(8);
            SolNumber = line(10:13);
            if strcmp(SolNumber, '----')
                SolN(iRow,1) = iRow;
            else
                SolN(iRow,1) = str2num(SolNumber);
            end
            T(iRow,1) = line(15);
            DATA_START(iRow,:) = line(17:28);
            DATA_END(iRow,:)   = line(30:41);
            Antenna(iRow,:)   = line(43:62);
            SerNum =  line(64:end);
            SN(iRow,1:length(SerNum)) = SerNum;
        end
        disp(fgetl(fileID));
        fclose(fileID);
        ANTENNA = struct('CODE',SiteName,'PT',PT,'SolN',SolN,'T',T, ...
            'DATA_START',DATA_START,'DATA_END',DATA_END, ...
            'Antenna',Antenna,'SN',SN);
        SITE.ANTENNA= ANTENNA;
     end
    % ----- parsing Antenna end ---------

    % ------ parsing GPS Phase Center ------------
     if iData == 7 % 'SITE/GPS_PHASE_CENTER'
        fileID = fopen(tmpFile);
        disp(fgetl(fileID));
%         disp(fgetl(fileID));
        line = fgetl(fileID);
        word = line(2:22);
        if ismember(word , {'________TYPE________','DESCRIPTION_________'})
            disp(line); 
        else
            disp(line);
            disp(fgetl(fileID));
            Len = Len - 1;
        end
        Antenna = repmat(char(0),Len-3,20);
        SN      = repmat(char(0),Len-3,5);
        Comment = repmat(char(0),Len-3,10);
        L1_PCO  = zeros(Len-3,3);
        L2_PCO  = zeros(Len-3,3);
        for iRow = 1:Len-3
            line = fgetl(fileID);
            Antenna(iRow,:) = line(2:21);
            SN(iRow,:) = line(23:27);
            L1_U = str2double(line(29:34));
            L1_N = str2double(line(36:41));
            L1_E = str2double(line(43:48));
            L1_PCO(iRow,:) = [L1_U, L1_N, L1_E];           
            L2_U = str2double(line(50:55));
            L2_N = str2double(line(57:62));
            L2_E = str2double(line(64:69));
            L2_PCO(iRow,:) = [L2_U, L2_N, L2_E];
            Comm = line(71:end);
            Comment(iRow,1:length(Comm)) = Comm;
        end
        disp(fgetl(fileID));
        fclose(fileID);
        GPS_PHASE_CENTER = struct('Antenna',Antenna,'SN',SN, ...
            'L1_PCO',L1_PCO,'L2_PCO',L2_PCO,'Comment',Comment);
        SITE.GPS_PHASE_CENTER = GPS_PHASE_CENTER;
     end
    % ----- parsing Phase Center end ---------
    
    % ------ parsing ECCENTRICITY ------------
    if iData == 8   % 'SITE/ECCENTRICITY'
        fileID = fopen(tmpFile);
        disp(fgetl(fileID));
        line = fgetl(fileID);
        word = line(2:5);
        if ismember( word, {'CODE', 'SITE'})
            disp(line);
            % start parsing table
        else
            disp(line);
            disp(fgetl(fileID));
            Len = Len - 1 ;
        end
        SiteName    = repmat(char(0),Len-3,4);
        PT          = repmat(char(0),Len-3,1);
        SolN        = zeros(Len-3,1);
        T           = repmat(char(0),Len-3,1);
        DATA_START  = repmat(char(0),Len-3,12);
        DATA_END    = repmat(char(0),Len-3,12);
        AXE         = repmat(char(0),Len-3,3);
        Ecc_UNE = zeros(Len-3,3);
        for iRow = 1:Len-3
            line = fgetl(fileID);
            SiteName(iRow,:) = line(2:5);
            PT(iRow,1) = line(8);
            SolNumber = line(10:13);
            if strcmp(SolNumber, '----')
                SolN(iRow,1) = iRow;
            else
                SolN(iRow,1) = str2num(SolNumber);
            end
            T(iRow,1) = line(15);
            DATA_START(iRow,:) = line(17:28);
            DATA_END(iRow,:)   = line(30:41);
            AXE(iRow,:)   = line(43:45);
            Ecc_U = str2double(line(47:54));
            Ecc_N = str2double(line(56:63));
            Ecc_E = str2double(line(65:72));
            Ecc_UNE(iRow,:) = [Ecc_U, Ecc_N, Ecc_E];
        end
        disp(fgetl(fileID));
        fclose(fileID);
        ECCENTRICITY = struct(  'CODE',SiteName,...
                                'PT',PT,...
                                'SolN',SolN,...
                                'T',T, ...
                                'DATA_START',DATA_START,...
                                'DATA_END',DATA_END,...
                                'Ecc_UNE',Ecc_UNE);
        SITE.ECCENTRICITY = ECCENTRICITY;
    end
    % ----- parsing ECCENTRICITY end ---------
    
    % ------ parse solution epochs ------- ok
     if iData == 9  % 'SOLUTION/EPOCHS'
        fileID = fopen(tmpFile);
        disp(fgetl(fileID));
        disp(fgetl(fileID)); 
        SiteName    = repmat(char(0),Len-3,4);
        PT          = repmat(char(0),Len-3,1);
        SolN        = zeros(Len-3,1);
        DATA_START  = repmat(char(0),Len-3,12);
        DATA_END    = repmat(char(0),Len-3,12);
        MEAN_EPOCH  = repmat(char(0),Len-3,12);
        for iRow = 1:Len-3
            line = fgetl(fileID);
            SiteName(iRow,:) = line(2:5);
            PT(iRow,1) = line(8);
            SolNumber = line(10:13);
            if strcmp(SolNumber, '----')
                SolN(iRow,1) = iRow;
            else
                SolN(iRow,1) = str2num(SolNumber);
            end
            DATA_START(iRow,:) = line(17:28);
            DATA_END(iRow,:)   = line(30:41);
            MEAN_EPOCH(iRow,:) = line(43:54);
        end
        disp(fgetl(fileID));
        fclose(fileID);
        EPOCHS = struct('CODE',SiteName, ...
                        'PT',PT, ...
                        'SolN',SolN, ...
                        'DATA_START',DATA_START, ...
                        'DATA_END',DATA_END, ...
                        'MEAN_EPOCH',MEAN_EPOCH);
        SOLUTION.EPOCHS = EPOCHS;
     end
    % ------ parse solution epochs end----

    % ------ parse crd and vel ----------- 
    %  parse CRD and VEL matrix
    % 'SOLUTION/ESTIMATE' and  'SOLUTION/APRIORI'
    if iData == 10 || iData == 11 
        fileID = fopen(tmpFile);
        disp(fgetl(fileID));
        disp(fgetl(fileID)); 
        NumberOfEntries = (Len-3)/6;       
        CRD_table     = nan(NumberOfEntries,3);
        CRD_STD_table = nan(NumberOfEntries,3);
        VEL_table     = nan(NumberOfEntries,3);
        VEL_STD_table = nan(NumberOfEntries,3);        
        for iBlock = 1:NumberOfEntries
            Value      = nan(1,6);
            Std_dev    = nan(1,6);
            Constrains = nan(1,6);            
            for iRow = 1:6            
                line = fgetl(fileID);
                index = str2double(line(1:6));            
                Constrains(iRow) = str2double(line(46));
                Value(iRow) = str2double(line(48:69));
                Std_dev(iRow) = str2double(line(70:80));
            end
            Site = line(15:18);
            PT = line(21);
            SolN = (line(23:26));            
            StationData(iBlock,:) = {iBlock, Site, PT, SolN, Constrains};             
            CRD_table(iBlock,:) = Value(1:3); 
            CRD_STD_table(iBlock,:) = Std_dev(1:3);
            VEL_table(iBlock,:) = Value(4:6); 
            VEL_STD_table(iBlock,:) = Std_dev(4:6);
            
            Data = struct('CRD', CRD_table, 'VEL', VEL_table, ...
                'CRD_STD', CRD_STD_table, 'VEL_STD', VEL_STD_table);
            Records = struct('NumberOfStations', {NumberOfEntries}, ...
                'StationData', {StationData}, 'Data', Data);
        end
        
        ArrStDat = Records.StationData;
        Str_St_Data = struct('iBlock', {ArrStDat(:,1)}, 'Site', {ArrStDat(:,2)}, 'PT', {ArrStDat(:,3)}, 'SolN', {ArrStDat(:,4)}, 'Constr', {ArrStDat(:,5)});
        Records.StationData = Str_St_Data;
        
        disp(fgetl(fileID));
        fclose(fileID);
        
        if iData == 10
            SOLUTION.ESTIMATE = Records;
        end
        if iData == 11
            SOLUTION.APRIORI  = Records;
        end
    end
    %  ---- parse crd and vel end ---------
     
    % -----  parse covarianse matrix ------
    % 'SOLUTION/MATRIX_ESTIMATE L COVA' and 'SOLUTION/MATRIX_APRIORI L COVA'
    if iData == 12 || iData == 13     
        fileID = fopen(tmpFile);
        disp(fgetl(fileID));
        disp(fgetl(fileID));
        CovMat = nan(NumberOfEntries*6);
        for iRow = 1:Len-3
            line = fgetl(fileID);
            Elements = str2num(line);
            Row = Elements(1);
            Col = Elements(2);
            Params = Elements(3:end);
            for iParam = 1:length(Params)
                CovMat(Row,Col+iParam-1) = Params(iParam);
            end
        end
        disp(fgetl(fileID));
        fclose(fileID);
    %   Assign Records to structure
        if iData == 12
            SOLUTION.COVA_ESTIMATE = CovMat;
        end
        if iData == 13
            SOLUTION.COVA_APRIORI = CovMat;
        end
    end
    % ------- parse covarianse matrix end --------
end

end
end


SINEX = struct('SITE', SITE,'SOLUTION',SOLUTION );

% rm tmp.txt file
system(['rm ',tmpFile]);

disp('Done')

end