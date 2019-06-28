@doc doc"""
    Product{TM<:Tuple, TRanges<:Tuple, TSizes<:Tuple} <: Manifold

Product manifold $M_1 \times M_2 \times \dots \times M_n$ with product geometry.
`TRanges` and `TSizes` statically define the relationship between representation
of the product manifold and representations of point, tangent vectors
and cotangent vectors of respective manifolds.

# Constructor

    Product(M_1, M_2, ..., M_n)

generates the product manifold $M_1 \times M_2 \times \dots \times M_n$
"""
struct Product{TM<:Tuple, TRanges, TSizes} <: Manifold
    manifolds::TM
end

function Product(manifolds...)
    sizes = map(m -> representation_size(m, MPoint), manifolds)
    lengths = map(s -> prod(s), sizes)
    ranges = UnitRange{Int64}[]
    k = 1
    for len ∈ lengths
        push!(ranges, k:(k+len-1))
        k += len
    end
    TRanges = tuple(ranges...)
    TSizes = tuple(sizes...)
    return Product{typeof(manifolds), TRanges, TSizes}(manifolds)
end

function representation_size(M::Product, ::Type{T}) where {T}
    return (sum(map(m -> representation_size(m, T), M.manifolds)),)
end

manifold_dimension(M::Product) = sum(map(m -> manifold_dimension(m), M.manifolds))

struct ProductMetric <: Metric end

@traitimpl HasMetric{Product,ProductMetric}

function local_metric(::MetricManifold{<:Product,ProductMetric}, x)
    error("TODO")
end

function inverse_local_metric(M::MetricManifold{<:Product,ProductMetric}, x)
    error("TODO")
end

function uview_element(x::AbstractArray, range, shape::Size{S}) where S
    return SizedAbstractArray{Tuple{S...}}(uview(x, range))
end

function det_local_metric(M::MetricManifold{Product{<:Manifold,TRanges,TSizes},ProductMetric}, x) where {TRanges, TSizes}
    dets = map(ziptuples(M.manifolds, TRanges, TSizes)) do d
        return det_local_metric(d[1], view_element(x, d[2], d[3]))
    end
    return prod(dets)
end

function inner(M::Product{TM, TRanges, TSizes}, x, v, w) where {TM, TRanges, TSizes}
    subproducts = map(ziptuples(M.manifolds, TRanges, TSizes)) do t
        inner(t[1],
             uview_element(x, t[2], t[3]),
             uview_element(v, t[2], t[3]),
             uview_element(w, t[2], t[3]))
    end
    return sum(subproducts)
end

function exp!(M::Product{TM, TRanges, TSizes}, y, x, v) where {TM, TRanges, TSizes}
    map(ziptuples(M.manifolds, TRanges, TSizes)) do t
        exp!(t[1],
             uview_element(y, t[2], t[3]),
             uview_element(x, t[2], t[3]),
             uview_element(v, t[2], t[3]))
    end
    return y
end

function log!(M::Product{TM, TRanges, TSizes}, v, x, y) where {TM, TRanges, TSizes}
    map(ziptuples(M.manifolds, TRanges, TSizes)) do t
        log!(t[1],
             uview_element(v, t[2], t[3]),
             uview_element(x, t[2], t[3]),
             uview_element(y, t[2], t[3]))
    end
    return v
end
