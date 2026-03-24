function new = newFilter(row,col,color)

%NEWFILTER Create a solid-color image.
%   NEW = NEWFILTER(ROW, COL, COLOR) returns a ROW-by-COL-by-3 uint8 image
%   array filled with the specified COLOR.
%
%   Inputs:
%     ROW   - Positive integer specifying number of rows (height).
%     COL   - Positive integer specifying number of columns (width).
%     COLOR - 1x3 numeric vector with values in the range [0,255]
%             specifying the RGB color as [R G B].
%
%   Output:
%     NEW - ROW-by-COL-by-3 uint8 array where every pixel has the given
%           RGB color.
%
%   Example:
%     img = newFilter(200,300,[255 128 0]); % creates an orange image 200x300

arguments
    row (1,1) {mustBeInteger,mustBePositive}
    col (1,1) {mustBeInteger,mustBePositive}
    color (1,3) {mustBeBetween(color,0,255)}
end

new = zeros( row, col, 3, "uint8" );
new(:,:,1) = new(:,:,1) + color(1);
new(:,:,2) = new(:,:,2) + color(2);
new(:,:,3) = new(:,:,3) + color(3);

end