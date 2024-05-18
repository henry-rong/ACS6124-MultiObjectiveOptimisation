% compile EA toolbox

mex 'EA Toolbox'\sbx.c
mex 'EA Toolbox'\rank_prf.c
mex 'EA Toolbox'\rank_nds.c
mex 'EA Toolbox'\btwr.c
mex 'EA Toolbox'\crowdingNSGA_II.c
mex 'EA Toolbox'\find_nd.c
mex 'EA Toolbox'\find_prf.c
mex 'EA Toolbox'\fshare.c
mex 'EA Toolbox'\polymut.c
% mex 'EA Toolbox'\*.c

% compile hypervolume

mex -DVARIANT=4 Hypervolume\Hypervolume_MEX.c Hypervolume\hv.c Hypervolume\avl.c


