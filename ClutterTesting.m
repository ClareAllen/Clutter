%% Script to test the clutter aggregation method used in processing Siradel data
% results have been recorded and compared to expected results in
% ClutterTest_v1 worksheet Existing
% Only suitable for use where the size of the input and output area are completely aligned

%% Setup input data - equivalent to 20m data over a 320 x 320 m area
TestDataIn = reshape([22:25,1:21],5,5);
TestDataIn(TestDataIn>17) = -9999;
TestDataIn = kron(TestDataIn,ones(3));
TestDataIn = [TestDataIn;TestDataIn(end,:)];
TestDataIn = [TestDataIn,TestDataIn(:,end)];

%% Inputs - test area allows for 40, 80, 160 m outputs
ResolutionIn = 20;
ResolutionOut = 40;

ReductionFactor = ResolutionOut/ResolutionIn; % 2 = 20m in 40m out
[nrowsIn,ncolsIn] = size(TestDataIn);
nrowsOut = floor(nrowsIn/ReductionFactor);
ncolsOut = floor(ncolsIn/ReductionFactor);

ClutterCount = NaN(ncolsOut,nrowsOut,17);
CodeOrder = [-9999;15;14;13;12;11;10;9;8;16;17;6;4;7;5;1;3;2]; % ordered by priority of class if null reduced category null
for kk = 1:18
    CodeInd = TestDataIn == CodeOrder(kk);
    ClutterCount(:,:,kk) = SumElementsDownsize_fun(CodeInd,ReductionFactor);
end

[~,ClutterLayer] = max(ClutterCount,[],3);
ClutterCode = CodeOrder(ClutterLayer);