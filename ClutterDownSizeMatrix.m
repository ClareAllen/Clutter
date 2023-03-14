%% Downsize clutter data
% for each M x M input grid (reduction factor M can be specified by user)
%      If there is a dominant type, in term of number of pixels of such type, 
%         (e.g. 8 x Building_Block, 9 x Open, 8 x River, the dominant type is Open) 
%      Then apply the dominant type to the sub grid
%      Else, i.e. there are two or more types have equal number of pixels, 
%         which are greater than others (e.g. 7 x Building_Block, 9 x Open, 9 x River)
%      Then apply the type with higher preferable index 
%                (as above example with following preferable list, the selected type is Open)
%
% Code	Type	          Group	PreferableIndex	Layer
% 15	Building_Block          G	17	1
% 14	Urban_high_dense        G	16	2
% 13	Urban_dense             F	15	3
% 12	Urban_mean_dense        F	14	4
% 11	Urban                   F	13	5
% 10	Residential_dense       E	12	6
% 9	    Residential             D	11	7
% 8	    Village                 D	10	8
% 16	Industry                D	9	9
% 17	Airport                 D	8	10
% 6	    Forest                  C	7	11
% 4	    Open                    B	6	12
% 7	    Park                    B	5	13
% 5     Low_Dense_Vegetation	B	4	14
% 1     Sea                     A	3	15
% 3     Lake                    A	2	16
% 2     River                   A	1	17

%% Inputs
ResolutionIn = 20;
ResolutionOut = 200;

%%
ReductionFactor = ResolutionOut/ResolutionIn; % 2 = 20m in 40m out
FolderIn = ['\\RSH-MAP-DATA\Mapping Data\DLU\DLU_',num2str(ResolutionIn),'m\'];
FolderOut = ['\\RSH-MAP-DATA\Mapping Data\DLU\DLU_',num2str(ResolutionOut),'m\'];

for ii = -2:9
    for jj = -3:13
        FileNameIn = ['DLU_',num2str(ResolutionIn),'m_', num2str(ii), '_', num2str(jj), '.asc'];
        FileNameOut = ['DLU_',num2str(ResolutionOut),'m_', num2str(ii), '_', num2str(jj), '.asc'];
        GridIn = GridASCII.Open([FolderIn FileNameIn]);
        GridOut = GridASCII(GridIn.xllcorner,GridIn.yllcorner,GridIn.ncols/ReductionFactor,GridIn.nrows/ReductionFactor,GridIn.cellsize*ReductionFactor,GridIn.nodata_value);

        ClutterCount = NaN(GridOut.nrows,GridOut.ncols,17);

% % % %         % Set priority J.Wang code
% % % %         preferableIndex = [3,1,2,6,4,7,5,10,11,12,13,14,15,16,17,9,8];
% % % %         [~, typeIndexPreferableOrder] = sort(preferableIndex,2,'descend');
        CodeOrder = [GridIn.nodata_value;15;14;13;12;11;10;9;8;16;17;6;4;7;5;1;3;2]; % ordered by priority of class if null reduced category null


        for kk = 1:18
            CodeInd = GridIn.data == CodeOrder(kk);
            ClutterCount(:,:,kk) = SumElementsDownsize_fun(CodeInd,ReductionFactor);
        end

        [~,ClutterLayer] = max(ClutterCount,[],3);
        ClutterCode = CodeOrder(ClutterLayer);

        GridOut.data = ClutterCode;
        fig1 = figure('units','normalized','outerposition',[0 0 0.9 0.9]);
        subplot(1,2,1); image(GridIn.data);axis square;title([num2str(ResolutionIn),'m grid']);colorbar;caxis([1 17]);
        subplot(1,2,2); image(GridOut.data);axis square;title([num2str(ResolutionOut),'m grid']);colorbar;caxis([1 17]);
        saveas(fig1,[FolderOut 'Check_' num2str(ii) '_' num2str(jj) '.jpg'],'jpeg');
        close(fig1);
        Save(GridOut, [FolderOut FileNameOut]);
        clearvars -except FolderIn FolderOut ResolutionIn ResolutionOut ReductionFactor ii jj 
    end
end



