function [Out] = SumElementsDownsize_fun(data,k)
% Sums data values over k x k elements.

SumOverCol = movsum(data,k,'Endpoints','discard');
SumOverRow = movsum(SumOverCol',k,'Endpoints','discard')';

% Thin out overlapping elements
[m,n] = size(SumOverRow);

Row_nums = 1:k:m;
Col_nums = 1:k:n;

Out = SumOverRow(Row_nums,Col_nums);

end

