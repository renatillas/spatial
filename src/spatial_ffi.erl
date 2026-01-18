-module(spatial_ffi).
-export([box_intersects/4, box_contains_point/3, sphere_intersects/4,
         distance_squared/2, distance/2, compute_bounds/1, merge_bounds/4]).

%% Fast AABB (Box-Box) intersection test
%% Returns true if two axis-aligned bounding boxes intersect
box_intersects({vec3, MinAX, MinAY, MinAZ}, {vec3, MaxAX, MaxAY, MaxAZ},
               {vec3, MinBX, MinBY, MinBZ}, {vec3, MaxBX, MaxBY, MaxBZ}) ->
    (MinAX =< MaxBX) andalso (MaxAX >= MinBX) andalso
    (MinAY =< MaxBY) andalso (MaxAY >= MinBY) andalso
    (MinAZ =< MaxBZ) andalso (MaxAZ >= MinBZ).

%% Fast box contains point test
%% Returns true if a point is inside an axis-aligned bounding box
box_contains_point({vec3, MinX, MinY, MinZ}, {vec3, MaxX, MaxY, MaxZ},
                   {vec3, PX, PY, PZ}) ->
    (PX >= MinX) andalso (PX =< MaxX) andalso
    (PY >= MinY) andalso (PY =< MaxY) andalso
    (PZ >= MinZ) andalso (PZ =< MaxZ).

%% Fast sphere-sphere intersection test
sphere_intersects({vec3, CenterAX, CenterAY, CenterAZ}, RadiusA,
                  {vec3, CenterBX, CenterBY, CenterBZ}, RadiusB) ->
    DX = CenterAX - CenterBX,
    DY = CenterAY - CenterBY,
    DZ = CenterAZ - CenterBZ,
    DistSq = DX * DX + DY * DY + DZ * DZ,
    RadiusSum = RadiusA + RadiusB,
    DistSq =< RadiusSum * RadiusSum.

%% Fast distance squared calculation
distance_squared({vec3, AX, AY, AZ}, {vec3, BX, BY, BZ}) ->
    DX = AX - BX,
    DY = AY - BY,
    DZ = AZ - BZ,
    DX * DX + DY * DY + DZ * DZ.

%% Fast distance calculation
distance({vec3, AX, AY, AZ}, {vec3, BX, BY, BZ}) ->
    DX = AX - BX,
    DY = AY - BY,
    DZ = AZ - BZ,
    math:sqrt(DX * DX + DY * DY + DZ * DZ).

%% Compute bounding box from list of positions
compute_bounds([]) ->
    %% Return a default large bounding box if empty
    {{vec3, 1.0e10, 1.0e10, 1.0e10}, {vec3, -1.0e10, -1.0e10, -1.0e10}};
compute_bounds([{vec3, X, Y, Z} | Rest]) ->
    compute_bounds_loop(Rest, X, Y, Z, X, Y, Z).

compute_bounds_loop([], MinX, MinY, MinZ, MaxX, MaxY, MaxZ) ->
    {{vec3, MinX, MinY, MinZ}, {vec3, MaxX, MaxY, MaxZ}};
compute_bounds_loop([{vec3, X, Y, Z} | Rest], MinX, MinY, MinZ, MaxX, MaxY, MaxZ) ->
    NewMinX = min(MinX, X),
    NewMinY = min(MinY, Y),
    NewMinZ = min(MinZ, Z),
    NewMaxX = max(MaxX, X),
    NewMaxY = max(MaxY, Y),
    NewMaxZ = max(MaxZ, Z),
    compute_bounds_loop(Rest, NewMinX, NewMinY, NewMinZ, NewMaxX, NewMaxY, NewMaxZ).

%% Merge two bounding boxes
merge_bounds({vec3, MinAX, MinAY, MinAZ}, {vec3, MaxAX, MaxAY, MaxAZ},
             {vec3, MinBX, MinBY, MinBZ}, {vec3, MaxBX, MaxBY, MaxBZ}) ->
    {{vec3, min(MinAX, MinBX), min(MinAY, MinBY), min(MinAZ, MinBZ)},
     {vec3, max(MaxAX, MaxBX), max(MaxAY, MaxBY), max(MaxAZ, MaxBZ)}}.
