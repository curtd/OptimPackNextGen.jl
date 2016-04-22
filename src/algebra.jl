#
# algebra.jl --
#
# Implement basic operations for *vectors*.  Here arrays of any rank are
# considered as *vectors*, the only requirements are that, when combining
# *vectors*, they have the same type and dimensions.  These methods are
# intended to be used for numerical optimization and thus, for now,
# elements must be real (not complex).
#
#------------------------------------------------------------------------------
#
# This file is part of TiPi.jl licensed under the MIT "Expat" License.
#
# Copyright (C) 2015-2016, Éric Thiébaut & Jonathan Léger.
#
#------------------------------------------------------------------------------

module Algebra

export inner, norm1, norm2, normInf
export swap!, update!, combine!

# Use the same floating point type for scalars as in TiPi.
import ..Float

"""
### Euclidean norm

The Euclidean (L2) norm of `v` can be computed by:
```
    norm2(v)
```
"""
function norm2{T<:AbstractFloat,N}(v::Array{T,N})
    s::T = zero(T)
    @simd for i in 1:length(v)
        @inbounds s += v[i]*v[i]
    end
    return Float(sqrt(s))
end

"""
### L1 norm

The L1 norm of `v` can be computed by:
```
    norm1(v)
```
"""
function norm1{T<:AbstractFloat,N}(v::Array{T,N})
    s::T = zero(T)
    @simd for i in 1:length(v)
        @inbounds s += abs(v[i])
    end
    return Float(s)
end

"""
### Infinite norm

The infinite norm of `v` can be computed by:
```
    normInf(v)
```
"""
function normInf{T<:AbstractFloat,N}(v::Array{T,N})
    s::T = zero(T)
    @simd for i in 1:length(v)
        @inbounds s = max(s, abs(v[i]))
    end
    return Float(s)
end

"""
### Compute scalar product

The call:
```
    inner(x,y)
```
computes the inner product (a.k.a. scalar product) between `x` and `y` (which
must have the same size).  The triple inner product between `w`, `x` and `y`
can be computed by:
```
    inner(w,x,y)
```
Finally:
```
    inner(sel, x, y)
```
computes the sum of the product of the elements of `x` and `y` whose indices
are given by the `sel` argument.
"""
function inner{T<:AbstractFloat,N}(x::Array{T,N}, y::Array{T,N})
    @assert(size(x) == size(y))
    s::T = 0
    @simd for i in 1:length(x)
        @inbounds s += x[i]*y[i]
    end
    return Float(s)
end

function inner{T<:AbstractFloat,N}(w::Array{T,N}, x::Array{T,N}, y::Array{T,N})
    @assert(size(x) == size(w))
    @assert(size(y) == size(w))
    s::T = 0
    @simd for i in 1:length(w)
        @inbounds s += w[i]*x[i]*y[i]
    end
    return Float(s)
end

function inner{T<:AbstractFloat,N}(sel::Vector{Int}, x::Array{T,N}, y::Array{T,N})
    @assert(size(y) == size(x))
    s::T = 0
    const n = length(x)
    @simd for i in 1:length(sel)
        j = sel[i]
        1 <= j <= n || throw(BoundsError())
        @inbounds s += x[j]*y[j]
    end
    return Float(s)
end

"""
### Exchange contents

The call:
```
    swap!(x, y)
```
exchanges the contents of `x` and `y` (which must have the same size).
"""
function swap!{T,N}(x::Array{T,N}, y::Array{T,N})
    @assert(size(x) == size(y))
    temp::T
    @inbounds begin
        @simd for i in 1:length(x)
            temp = x[i]
            x[i] = y[i]
            y[i] = temp
        end
    end
end

"""
### Increment an array by a scaled step

The call:
```
    update!(dst, alpha, x)
```
increments the components of the destination *vector* `dst` by those of
`alpha*x`.  The code is optimized for some specific values of the multiplier
`alpha`.  For instance, if `alpha` is zero, then `dst` left unchanged without
using `x`.
"""
function update!{T<:AbstractFloat,N}(dst::Array{T,N},
                                     a::T, x::Array{T,N})
    @assert(size(x) == size(dst))
    const n = length(dst)
    @inbounds begin
        if a == one(T)
            @simd for i in 1:n
                dst[i] += x[i]
            end
        elseif a == -one(T)
            @simd for i in 1:n
                dst[i] -= x[i]
            end
        elseif a != zero(T)
            @simd for i in 1:n
                dst[i] += a*x[i]
            end
        end
    end
end

"""
### Linear combination of arrays

The calls:
```
    combine!(dst, alpha, x)
    combine!(dst, alpha, x, beta, y)
```
stores the linear combinations `alpha*x` and `alpha*x + beta*y` into the
destination array `dst`.  The code is optimized for some specific values of the
coefficients `alpha` and `beta`.  For instance, if `alpha` (resp. `beta`) is
zero, then the contents of `x` (resp. `y`) is not used.

The source array(s) and the destination an be the same.  For instance, the two
following lines of code produce the same result:
```
    combine!(dst, 1, dst, alpha, x)
    update!(dst, alpha, x)
```
"""

function combine!{T<:Real,N}(dst::Array{T,N}, a::T, x::Array{T,N})
    @assert(size(x) == size(dst))
    const n = length(dst)
    @inbounds begin
        if a == zero(T)
            @simd for i in 1:n
                dst[i] = a
            end
        elseif a == one(T)
            @simd for i in 1:n
                dst[i] = x[i]
            end
        elseif a == -one(T)
            @simd for i in 1:n
                dst[i] = -x[i]
            end
        else
            @simd for i in 1:n
                dst[i] = a*x[i]
            end
        end
    end
end

function combine!{T<:AbstractFloat,N}(dst::Array{T,N},
                                      a::T, x::Array{T,N},
                                      b::T, y::Array{T,N})
    @assert(size(x) == size(dst))
    @assert(size(y) == size(dst))
    const n = length(dst)
    @inbounds begin
        if a == zero(T)
            combine!(dst, b, y)
        elseif b == zero(T)
            combine!(dst, a, x)
        elseif a == one(T)
            if b == one(T)
                @simd for i in 1:n
                    dst[i] = x[i] + y[i]
                end
            elseif b == -one(T)
                @simd for i in 1:n
                    dst[i] = x[i] - y[i]
                end
            else
                @simd for i in 1:n
                    dst[i] = x[i] + b*y[i]
                end
            end
        elseif a == -one(T)
            if b == one(T)
                @simd for i in 1:n
                    dst[i] = y[i] - x[i]
                end
            elseif b == -one(T)
                @simd for i in 1:n
                    dst[i] = -x[i] - y[i]
                end
            else
                @simd for i in 1:n
                    dst[i] = b*y[i] - x[i]
                end
            end
        else
            if b == one(T)
                @simd for i in 1:n
                    dst[i] = a*x[i] + y[i]
                end
            elseif b == -one(T)
                @simd for i in 1:n
                    dst[i] = a*x[i] - y[i]
                end
            else
                @simd for i in 1:n
                    dst[i] = a*x[i] + b*y[i]
                end
            end
        end
    end
end

function update!{T<:AbstractFloat,N}(dst::Array{T,N},
                                     alpha::Real, x::Array{T,N})
    update!(dst, T(alpha), x)
end

function combine!{T<:Real,N}(dst::Array{T,N},
                             alpha::Real, x::Array{T,N})
    combine!(dst, T(alpha), x)
end

function combine!{T<:Real,N}(dst::Array{T,N},
                             alpha::Real, x::Array{T,N},
                             beta::Real,  y::Array{T,N})
    combine!(dst, T(alpha), x, T(beta), y)
end

end # module
