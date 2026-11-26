function seed = noiseSeed(imgName, type, level)
%NOISESEED Seed xac dinh tu (ten anh, loai nhieu, muc nhieu).
s = sprintf('%s|%s|%.6g', char(imgName), lower(char(type)), level);
h = uint64(5381);
for k = 1:numel(s)
    h = mod(h * 33 + uint64(s(k)), uint64(2^32 - 1));  % djb2, khong tran
end
seed = double(h);
end