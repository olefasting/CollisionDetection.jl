using CollisionDetection
using StaticArrays
using Base.Test
using JLD
CD = CollisionDetection

@test CD.childsector([1,1,1],[0,0,0]) == 7
@test CD.childsector([-1,1,-1],[0,0,0]) == 2

@test CD.childsector([-1,1,-1,1],[0,0,0,0]) == 10
@test CD.childsector([1,1],[0,0]) == 3

@test CD.childcentersize(SVector(0.,0.,0.), 1., 3) == (SVector(0.5,0.5,-0.5), 0.5)
@test CD.childcentersize(SVector(0.,0.,0.), 2., 7) == (SVector(1.0,1.0,1.0), 1.0)

@test CD.childcentersize(SVector(1.,1.,1.,1.), 2., 9) == (SVector(2.,0.,0.,2.), 1.)

d, n = 3, 200
data = SVector{d,Float64}[rand(SVector{d,Float64}) for i in 1:n]
radii = abs.(rand(n))
tree = CD.Octree(data, radii)

@test length(tree) == n

println("Testing allways true iterator")
sz = 0
for box in CD.boxes(tree)
    sz += length(box)
end
@test sz == n

println("Testing allways false iterator")
sz = 0
for box in CD.boxes(tree, (c,s)->false)
    sz += length(box.data)
end
@test sz == 0

println("Testing query for box in sector [7,0]")
sz = 0
for box in CD.boxes(tree, (c,s)->CD.fitsinbox([1,1,1]/8,0,c,s))
    sz += length(box)
end
@show sz

T = Float64
P = SVector{2,T}
n = 40000
data = P[rand(P) for i in 1:n]
radii = abs.(rand(T,n))
tree = CD.Octree(data, radii)

println("Testing allways true iterator [2D]")
sz = 0
for box in CD.boxes(tree)
    sz += length(box)
end
@test sz == n

println("Testing allways false iterator [2D]")
sz = 0
for box in CD.boxes(tree, (c,s)->false)
    sz += length(box.data)
end
@test sz == 0

println("Testing query for box in sector [7,0], [2D]")
sz = 0
for box in CD.boxes(tree, (c,s)->CD.fitsinbox([1,1]/8,0,c,s))
    sz += length(box)
end
@show sz


## Test the case of degenerate bounding boxes
fn = joinpath(dirname(@__FILE__),"assets","front.jld")
V,F = jldopen(fn,"r") do file
        read(file, "V"), read(file, "F")
end

fn = joinpath(dirname(@__FILE__),"assets","back.jld")
U,G = jldopen(fn,"r") do file
        read(file, "V"), read(file, "F")
end

radii = zeros(length(V))
tree = Octree(V, radii)

tree_ctr, tree_hs = tree.center, tree.halfsize

u = U[3]
atol = sqrt(eps())
@test norm(u-V[4]) < atol
pred(c,s) = fitsinbox(Array(u), 0.0, c, s+atol)
@test pred(tree_ctr, tree_hs)
it = boxes(tree, pred)
st = start(it)
@test !done(it, st)
