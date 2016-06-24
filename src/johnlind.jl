# Implements the Johnson-Lindenstauss resistance upperbounding
# TODO: not optimized for speed - let's see how resistance estimates improve the number of nonzeros at the end

function johnlind{Tv,Ti}(a::SparseMatrixCSC{Tv,Ti}; eps::Float64 = 0.5, retXhat::Bool = false)

	n = a.n
	# m = ceil(Int64, length(a.nzval) / 2)
	m = length(a.nzval)
	dhat = ceil(Int64, 4 * log(m) / eps^2)

	P = ones(dhat, m)
	for i in 1:dhat
		for j in 1:m
			if rand() < 1/2
				P[i,j] = -P[i,j]
			end
		end
	end
	# we want ||P * x|| = ||x||
	P = P / sqrt(dhat)

	# compute B
	U = Ti[]
	V = Ti[]
	W = Tv[]

	pos = 1
	for i in 1:length(a.nzval)
		while a.colptr[pos + 1] <= i
			pos = pos + 1
		end

		p = a.rowval[i]
		q = pos
		w = sqrt(a.nzval[i])

		if p > q
			aux = p
			p = q
			q = aux
		end

		# multiply B by W
		push!(U, i)
		push!(V, p)
		push!(W, w)

		push!(U, i)
		push!(V, q)
		push!(W, -w)
	end

	B = sparse(U, V, W)

	# Get bs = P * W^(1/2) * B. We already multiplied W by B. Solve for each line. dims are dhat x n
	bs = P * B / sqrt(2)

	la = lap(a)
	f = lapWrapSolver(augTreeSolver,la,tol=1e-6,maxits=1000)

	# xhat = P * W^(1/2) * B * L ^-1 * ei
	xhat = zeros(n, dhat)
	for i in 1:dhat
		b = reshape(bs[i,:], n)
		b = b - mean(b)
		xhat[:,i] = f(b)
	end

	if retXhat
		return xhat
	end

	# compute the effective resistance
	reff = copy(a)
	pos = 1
	for i in 1:m
		while a.colptr[pos + 1] <= i
			pos = pos + 1
		end

		p = a.rowval[i]
		q = pos

		reff.nzval[i] = norm(xhat[p,:] - xhat[q,:])^2
	end

	return reff

end