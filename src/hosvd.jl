"""
High-order singular value decomposition (HO-SVD).
"""
function hosvd(tensor::StridedArray{T,N}, core_dims::NTuple{N, Int};
               pad_zeros::Bool=false, compute_error::Bool=false) where {T,N}
    pad_zeros || _check_tensor(tensor, core_dims)

    factors = map(1:N) do i
        X = _col_unfold(tensor, i)
        f = eigen(Symmetric(X'X), max(1, size(X,2)-core_dims[i]+1):size(X,2)).vectors
        if pad_zeros && size(f, 2) < core_dims[i] # fill missing factors with zeros
            f = hcat(f, zeros(T, size(tensor, i), core_dims[i]-size(f, 2)))
        end
        mapslices(_check_sign, f, dims=1)
    end

    res = Tucker(factors, tensorcontractmatrices(tensor, factors))
    compute_error && _set_rel_residue(res, tensor)
    return res
end

hosvd(tensor::StridedArray, r::Int;
      pad_zeros::Bool=false, compute_error::Bool=false) =
    hosvd(tensor, ntuple(_ -> r, ndims(tensor)),
          pad_zeros=pad_zeros, compute_error=compute_error)
