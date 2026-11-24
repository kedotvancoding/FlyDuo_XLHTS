function [P, R, F1, nMatch] = matchMinutiae(minuTest, minuRef, params)
    if nargin < 3 || isempty(params)
        params = struct();
    end
    if isfield(params, 'dist'),    maxDist  = params.dist;    else, maxDist  = 14;    end
    if isfield(params, 'angle'),   maxAngle = params.angle;   else, maxAngle = pi/9;  end
    if isfield(params, 'useType'), useType  = params.useType; else, useType  = false; end

    nTest = size(minuTest, 1);
    nRef  = size(minuRef, 1);

    if nTest == 0 || nRef == 0
        nMatch = 0;
        P = 0;
        R = 0;
        F1 = 0;
        return;
    end

    % Ma tran khoang cach Euclidean (nTest x nRef)
    dx = minuTest(:, 1) - minuRef(:, 1)';
    dy = minuTest(:, 2) - minuRef(:, 2)';
    D = hypot(dx, dy);

    % Ma tran sai khac goc theo CONVENTIONS muc 2 (mod pi)
    dAngle = abs(mod(minuTest(:, 3) - minuRef(:, 3)' + pi/2, pi) - pi/2);

    % Kiem tra dieu kien ghep hop le
    valid = (D <= maxDist) & (dAngle <= maxAngle);
    if useType
        valid = valid & (minuTest(:, 4) == minuRef(:, 4)');
    end

    % Ghep 1-1 uu tien cac cap co khoang cach nho nhat truoc
    [iIdx, jIdx] = find(valid);
    if isempty(iIdx)
        nMatch = 0;
        P = 0;
        R = 0;
        F1 = 0;
        return;
    end

    linIdx = sub2ind([nTest, nRef], iIdx, jIdx);
    [~, order] = sort(D(linIdx), 'ascend');
    iIdx = iIdx(order);
    jIdx = jIdx(order);

    usedTest = false(nTest, 1);
    usedRef  = false(nRef, 1);
    nMatch = 0;

    for k = 1:numel(iIdx)
        it = iIdx(k);
        jr = jIdx(k);
        if ~usedTest(it) && ~usedRef(jr)
            usedTest(it) = true;
            usedRef(jr)  = true;
            nMatch = nMatch + 1;
        end
    end

    % Tinh P, R, F1
    P = nMatch / nTest;
    R = nMatch / nRef;
    if (P + R) > 0
        F1 = 2 * P * R / (P + R);
    else
        F1 = 0;
    end
end
