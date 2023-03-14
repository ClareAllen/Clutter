classdef GridASCII < handle
%GridASCII Class for handling Grid ASCII file
%
% Author:           Jerry Wang
%                   Ofcom
% Last Modified:    2015/11/09
    
    properties (SetAccess = protected)
        ncols = 0; 
        nrows = 0;
    end
    
    properties
        xllcorner = 0;
        yllcorner = 0;
    end
    
    properties (Dependent) 
        cellsize;
        nodata_value;
    end
    properties (Access = protected)
        nodata_value_hidden = -9999; % nodata_value
        cellsize_hidden = 0; % cellsize
        decimaldigits_hidden = 0;
    end
    
    properties
        data = []; % data grid
    end
    
    properties (Dependent) 
        decimaldigits; % the number of decimal digits to be printed into file
        xtrcorner; % top right top corner x
        ytrcorner; % top right corner y
    end
    
    methods
        
        function obj = GridASCII(xllcorner,yllcorner,ncols,nrows,cellsize,nodata_value)
        % Constructor 
            if nargin > 0
                if ncols < 1 || nrows < 1 || cellsize <= 0
                    error('null area !!');
                end
                obj.xllcorner = xllcorner;
                obj.yllcorner = yllcorner;
                obj.ncols = ncols;
                obj.nrows = nrows;
                obj.cellsize_hidden = cellsize;
                if nargin > 5, 
                    obj.nodata_value_hidden = nodata_value;
                end
                
                obj.data = repmat(nodata_value,nrows,ncols);
            end
        end
        
        function set.decimaldigits(obj, decimaldigits)
        % set cellsize
            if round(decimaldigits) ~= decimaldigits || decimaldigits < 0
                error('decimaldigits must none negative integer');
            end
            obj.decimaldigits_hidden = decimaldigits;
        end
        function decimaldigits = get.decimaldigits(obj)
        % get decimaldigits
            decimaldigits = obj.decimaldigits_hidden;
        end
        
        function set.cellsize(obj, cellsize)
        % set cellsize
            if cellsize <= 0
                error('cellsize must > 0');
            end
            obj.cellsize_hidden = cellsize;
        end
        function cellsize = get.cellsize(obj)
        % get cellsize
            cellsize = obj.cellsize_hidden;
        end
        
        function set.nodata_value(obj, nodata_value)
        % set nodata_value
            if ~isempty(obj.data)
                obj.data(obj.data == obj.nodata_value_hidden) = nodata_value;
            end
            obj.nodata_value_hidden = nodata_value;
        end
        function nodata_value = get.nodata_value(obj)
        % get nodata_value
            nodata_value = obj.nodata_value_hidden;
        end
        
        function ytrcorner = get.ytrcorner(obj)
        % get the top right corner y
            ytrcorner = obj.yllcorner + obj.cellsize * (max(obj.nrows,0)-1);
        end
        function xtrcorner = get.xtrcorner(obj)
        % get the top right corner x
            xtrcorner = obj.xllcorner + obj.cellsize * (max(obj.ncols,0)-1);
        end
    end
    
    methods
        
        function Save(obj, file_pathname)
        % Export data into GridASCII file
        % INPUT 
        %   file_pathname [optional]
            obj.verifydatasize();
            
            if nargin <2 || isempty(file_pathname)
                [filename, pathname]=uiputfile({'*.asc';'*.*'},'Save to GridASCII File');
                if length(filename)<2, return;  end    
                file_pathname = [pathname,filename];
            end
            
            % start to write
            fid=fopen(file_pathname,'w');
            fprintf('Writing Header ... \n');
            fprintf(fid,'ncols        %d\r\n',obj.ncols);
            fprintf(fid,'nrows        %d\r\n',obj.nrows);
            fprintf(fid,'xllcorner    %f\r\n',obj.xllcorner);
            fprintf(fid,'yllcorner    %f\r\n',obj.yllcorner);
            fprintf(fid,'cellsize     %f\r\n',obj.cellsize);
            fprintf(fid,['nodata_value %.',int2str(obj.decimaldigits),'f\r\n'],obj.nodata_value);
            
            
            formatSpec = repmat(['%.',int2str(obj.decimaldigits),'f '],1,obj.ncols);
            formatSpec = [formatSpec, '\r\n'];
            
            fprintf('Writing data ...');
            odata = transpose(flipud(obj.data));
            fprintf('...');
            fprintf(fid,formatSpec,odata);
            
            %{
            % write line by line
            fprintf('Writing |=>>');
            progress = 0;
            for kk=1:obj.nrows
                fprintf(fid,formatSpec,obj.data(obj.nrows + 1 - kk,:));
                
                if (kk/obj.nrows * 50) > progress
                    progress = progress + 1;
                    fprintf('\b\b=>>');
                end
            end;
            %}
            
            fprintf('DONE\n');
            fclose(fid);
        end
        
        function newobj = clone(obj)
        % deep copy to new obj
            obj.verifydatasize();
            newobj = GridASCII(obj.xllcorner,obj.yllcorner,obj.ncols,obj.nrows,obj.cellsize,obj.nodata_value);
            newobj.data = obj.data;
        end
        
        function replace(obj,org_value, new_value)
        % mapping data value 
        % INPUT
        %   org_value - the data value to be replaced
        %   new_value - the new data value to use
        %       org_value and new_value must have the same size
            org_value = org_value(:);
            new_value = new_value(:);
            valueN = length(org_value);
            if length(new_value) ~= valueN
                error('org_value and new_value must have the same size');
            end
            for kk = 1:valueN
                obj.data(obj.data == org_value(kk)) = new_value(kk);
            end
        end
        
        function downsized_obj = downsize(obj,factorN, fcnHandle_merge, varargin)
        % down sampling the data grid by factor N
        % INPUT
        %   factorN - the downsize factor
        %   fcnHandle_merge - the function handle for merge 
        %                     this func must take a vector of double and
        %                     return a 1x1 double
        % OUTPUT
        %   downsized_obj - new GridASCII obj after downsize
        % Example
        %   downsize a 20m grid to 100m grid, using the min data value of
        %   each 5x5 subgrid as the new grid value
        %       grid100m = grid20m.downsize(5, @min)
            obj.verifydatasize();
            if factorN < 2 || (mod(obj.nrows,factorN) + mod(obj.ncols,factorN) > 0)
                error('factorN (>1) must be common factor of nrows and ncols');
            end
            downsized_obj = GridASCII(obj.xllcorner,obj.yllcorner,...
                obj.ncols/factorN, obj.nrows/factorN,...
                obj.cellsize * factorN, obj.nodata_value);
            
            ind1 = int32(1:factorN);
            for kk = 1:downsized_obj.ncols
                for nn = 1:downsized_obj.nrows
                    subgrid = obj.data(ind1 + (nn-1)*factorN, ind1 + (kk-1)*factorN);
                    subgrid = subgrid(:);
                    subgrid = subgrid(subgrid ~= obj.nodata_value);
                    if isempty(subgrid)
                        downsized_obj.data(nn,kk) = obj.nodata_value;
                    else
                        downsized_obj.data(nn,kk) = fcnHandle_merge(subgrid, varargin{:});
                    end
                end
            end
        end
        
        function aH = plot(obj, aH, clims)
        % plotting the data in image
        % INPUT :
        %   aH [optional]- the handle to the target axes 
        %   clims [optional]- clims for imagesc func call
            
            if nargin <2 || isempty(aH)
                figure;
                aH = gca;
            end
            
            % do ploting
            ScaleX = [obj.xllcorner, obj.xtrcorner];
            ScaleY = [obj.yllcorner, obj.ytrcorner];
            
            cdata = obj.data;
            cdata(cdata == obj.nodata_value) = NaN;
            
            axes(aH);
            if nargin <3 || isempty(clims)
                ih = imagesc(ScaleX, ScaleY, cdata);
            else
                ih = imagesc(ScaleX, ScaleY, cdata, clims);
            end
            axis xy; axis image; box on;
            colormap('parula');
            colorbar;
            
            aH = get(ih,'parent');
        end
        
    end
    
    methods (Access = protected)
        
        function verifydatasize(obj)
        % verify the dimension of data
            [rN,cN] = size(obj.data);
            if rN == 0 || cN == 0 || rN ~= obj.nrows || cN ~= obj.ncols
                error('data dimension is wrong!!');
            end
        end
        
        function load_file(obj, file_pathname)
        % load data from file     
            % read the file
            headerinfo = GridASCII.ReadHeader(file_pathname);
            if isempty(headerinfo), return; end
            
            % read data
            formatSpec = repmat('%f ',1,headerinfo.ncols);
            tmpdata = repmat(headerinfo.nodata_value,headerinfo.nrows,headerinfo.ncols);
            
            fid=fopen(file_pathname,'r');
            lineN = 0;
            while true
                lineN = lineN +1;
                C = textscan(fid,formatSpec,'Delimiter','\r\n');
                if ~isempty(C{1}), break; end
                if lineN > 100, break; end
                fgetl(fid);
            end
            fclose(fid);
            if length(C) ~= headerinfo.ncols,
                error('reading data file error - dimension '); 
            end
            for kk = 1:headerinfo.ncols
                coldata = C{1,kk};
                if length(coldata) ~= headerinfo.nrows, 
                    error('reading data file error - dimension '); 
                end
                tmpdata(:,kk) = flipud(coldata);
            end
            
            obj.ncols = headerinfo.ncols;
            obj.nrows = headerinfo.nrows;
            obj.xllcorner = headerinfo.xllcorner;
            obj.yllcorner = headerinfo.yllcorner;
            obj.cellsize = headerinfo.cellsize;
            obj.nodata_value_hidden = headerinfo.nodata_value;
            obj.data = tmpdata;
            return;
            
        end
        
    end
    
    methods (Static)
        
        function obj = Open(file_pathname)
        % Load data file into a new obj
        % INPUT 
        %   file_pathname [optional]
            obj = [];
            % check the input
            if nargin < 1 || isempty(file_pathname)
                file_pathname = getfilenamepath();
                if isempty(file_pathname), return; end
            end
            
            obj = GridASCII;
            obj.load_file(file_pathname);
            if isempty(obj.data)
                obj = [];
            end
        end
        
        function headerinfo = ReadHeader(file_pathname)
            headerinfo = [];
            if nargin < 1 || isempty(file_pathname)
                file_pathname = getfilenamepath();
                if isempty(file_pathname), return; end
            end
            fid=fopen(file_pathname,'r');
            if fid<0 
                error('fail reading file !!');
            end;
            headflag = zeros(1,6);
            % read header
            lineN = 0;
            while ~feof(fid)
                if sum(headflag) == 6 % finish reading header
                    break;
                end
                readinline = fgetl(fid);
                % end of file 
                if readinline == -1,  continue; end 
                line = strtrim(readinline);
                % empty line
                if length(line) < 1, continue;  end
                % read header
                lineN = lineN +1;
                if lineN > 100, break; end
                
                line = lower(line);
                C = textscan(line,'ncols %f');
                if ~isempty(C{1}), headerinfo.ncols = C{1}; headflag(1) = 1; continue; end
                C = textscan(line,'nrows %f');
                if ~isempty(C{1}), headerinfo.nrows = C{1}; headflag(2) = 1; continue; end
                C = textscan(line,'xllcorner %f');
                if ~isempty(C{1}), headerinfo.xllcorner = C{1}; headflag(3) = 1; continue; end
                C = textscan(line,'yllcorner %f');
                if ~isempty(C{1}), headerinfo.yllcorner = C{1}; headflag(4) = 1; continue; end
                C = textscan(line,'cellsize %f');
                if ~isempty(C{1}), headerinfo.cellsize = C{1}; headflag(5) = 1; continue; end
                C = textscan(line,'nodata_value %f');
                if ~isempty(C{1}), headerinfo.nodata_value = C{1}; headflag(6) = 1; continue; end
                
            end
            fclose(fid);
            
            if sum(headflag) < 6, fclose(fid);error('reading file error: did not find all header values'); end
            if headerinfo.ncols < 1, fclose(fid);error('reading file error: ncols < 1'); end
            if headerinfo.nrows < 1, fclose(fid);error('reading file error: nrows < 1'); end
            
        end
    end
    
end

function file_pathname = getfilenamepath()
    file_pathname = [];
    [filename, pathname]=uigetfile({'*.asc';'*.*'},'Select GridASCII File');
    if length(filename)<4, 
        return; 
    end   
    file_pathname = [pathname, filename];
end
% EOF