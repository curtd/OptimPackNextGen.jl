#
# TiPi.jl --
#
# Toolkit for Inverse Problems and Imaging in Julia.
#
#------------------------------------------------------------------------------
#
# This file is part of TiPi.jl licensed under the MIT "Expat" License.
#
# Copyright (C) 2015, Éric Thiébaut & Jonathan Léger.
#
#------------------------------------------------------------------------------

module TiPi

export cost, cost!, prox, prox!, AbstractCost, HyperbolicEdgePreserving
export MDA
export goodfftdim, fftfreq, zeropad, pad

"""
`Float` is the type of all floating point scalar, it is currently an alias to
`Cdouble` which is itself an alias to `Float64`.
"""
typealias Float Cdouble

include("utils.jl")
include("AffineTransforms.jl")
include("algebra.jl")
include("kernels.jl")
include("interp.jl")
include("mda.jl")
include("lnsrch.jl")
include("quasi-newton.jl")
include("conjgrad.jl")
include("cost.jl")
include("smooth.jl")
include("hypersmooth.jl")
include("deconv.jl")

end # module
