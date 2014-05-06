function [SolutionStruct]= BISPICE_Train(varargin)

%------------------------------------------------------------------
% Dmitri (dmitrid@ufl.edu) - March 2012
%
%	SolutionStruct = BISPICE_Train(Data, BParameters)
% 
% INPUT
%		Data - 	D x N Matrix of data points. 
%			OR N x M x D HSI Image Data.	
%		BParameters - A structure generated by BISPICE_Parameters.m
%
% OUTPUT
%		SolutionStruct - A struct containing all estimated
%				 parameters.
%
% EXAMPLE
%		SS = BISPICE_Train(HylidImage.Data, BISPICE_Parameters());
%		plotSolution_BISPICE( SS, HylidImage, [], '');
%
%------------------------------------------------------------------
Data = double(varargin{1});
if (size(Data,3) ~= 1)
	Data 	 = reshape(Data, [size(Data,1)*size(Data,2), size(Data,3)])';
end

Parameters 	 = varargin{2};
pruneFlag 	 = 0;
Niter_Global = Parameters.iter;
[D N] 		 = size(Data);

%Initialization of endmembers : 
%Set endmembers to random pixels or user-specified values.
if (length(Parameters.initial_endmembers) <= 1)
    %Find Random Initial Endmembers
    randIndices	 = randperm(size(Data,2));
    randIndices	 = randIndices(1:Parameters.M);
    MPlus		 = Data(:,randIndices);
    Parameters.initial_endmembers = MPlus;
else
    %Use endmembers provided
    MPlus		 = Parameters.initial_endmembers;
end


[D R]		 = size(MPlus);
%Array storing pruned endmembers
KeptE		 = logical(ones( 1, R + R*(R-1)/2));
MPlusC		 = formProducts(MPlus);

%Initialization of proportions.
P			 = double([ ones(N,R)*(0.9/R), ones(N,R*(R-1)/2)*(0.1/(R*(R-1)/2))]  )';

%Calculation of initial error
P			 = unmix_quad_qpas(Data, MPlus, 0, P(1:R,:)', Parameters)';
Props		 = P(1:R,:)';
UpdateE		 = logical(ones(1,R));
disp(strcat('Initial Least Squares Error = ', num2str(LSErr(Data, P, [MPlus], Parameters.u, R, KeptE, UpdateE))));

P			 = double([ ones(N,R)*(0.9/R), ones(N,R*(R-1)/2)*(0.1/(R*(R-1)/2))]  )';

%Endmember update (First Iteration)
if (~Parameters.unmix_only)
    MPlus	 = Estimate_E(MPlus, P, Data, Parameters, KeptE, UpdateE);
end

%Alternating Optimization loop
ERR_ARRAY = [];
ERR_TMP = 1e20;
KeptE_ALT = ones(size(KeptE));
for t=2:Niter_Global

	%Update the proportions
	disp('Updating Proportions');
	FULL_E		 = [MPlus, MPlusC];

	%Prepare vectors with the corresponding values of Gamma_B or Gamma_L
	if (t < 5)
		GVector	 = [ones(1,R) * Parameters.gamma * t/5 , ones(1,R*(R-1)/2) * Parameters.bgamma * t/5];
	else
		GVector	 = [ones(1,R) * Parameters.gamma , ones(1,R*(R-1)/2) * Parameters.bgamma];
	end
	
	%Proportion's updated with QP. gamma_i,j is calculated inside here.
	P(KeptE,:)	 = unmix_quad_qpas_gam(Data, FULL_E(:,KeptE), GVector(KeptE), P(KeptE,:)', Parameters)';
	
	%This code can be used for just unmixing by specifying this parameter.
	if (Parameters.unmix_only) break; end
	
	%Recalculate objective function.
	disp('Updating Endmembers');
	L_E			 = LSErr(Data, P, [MPlus,MPlusC], Parameters.u, R, KeptE, UpdateE);
	disp(strcat('Least Squares Error = ', num2str(L_E)));

	%Update each endmember as a function of the others. Do this until convergence,
	%or until the limit specified in the parameters file is reached.
	MPlus2		 = MPlus;
	for i=1:Parameters.e_max_iter
		[MPlus3] = Estimate_E(MPlus2, P, Data, Parameters, KeptE, UpdateE);
		DIFF	 = norm(MPlus3 - MPlus2)/R;
		MPlus2	 = MPlus3;
		if (DIFF < Parameters.e_iter_cutoff) break; end;
	end
	
	DIFF		 = norm(MPlus2 - MPlus)/R;
	MPlus		 = MPlus2;
	MPlusC		 = formProducts(MPlus);

	% Quit if we converged
	ERR_CUR		 = LSErr(Data, P, [MPlus, MPlusC], Parameters.u, R, KeptE, UpdateE);
	ERR_ARRAY	 = [ERR_ARRAY , ERR_CUR];
	if (abs(ERR_TMP - ERR_CUR) < Parameters.cutoff) break; end

	%Prune Endmembers below pruning threshold
	pruneFlag	 = 0;
	pruneIndex	 = (KeptE) & (max(P')<Parameters.endmemberPruneThreshold);
	minmaxP		 = min(max(P'));

	%If there are any endmembers with proportions below threshold, prune them, otherwise continue to the next iteration.
	if(sum(pruneIndex) > 0 )
		disp(strcat('Pruned ', num2str(sum(pruneIndex)), ' Endmembers'));
		pruneFlag		 = 1;

		%Update the index of endmembers that are still in use.
	    KeptE			 = KeptE & (logical(1-pruneIndex))

		%Reset the bilinear endmembers if the corresponding linear endmember was pruned (optional)
		if (Parameters.resetBilinearOnPrune)
			disp(strcat('Saved ' ,num2str( sum(KeptE & ~KeptE_ALT)), ' Bilinear Terms using ResetOnPrune'));
		end

		%Zero out the corresponding proportion.
		P(pruneIndex,:)	 = zeros(sum(pruneIndex),size(P,2));

		%If a linear endmember was pruned.
		if (sum(pruneIndex(1:R)) > 0)
		    pruneFlag	 = 2;

			%Construct a mask representing all affected endmembers (including bilinear).
			MASK		 = GenerateMasks(R);
			for i=1:R 
				MASK(i,i)= 1; 
			end
			MASK		 = logical(sum(MASK(pruneIndex(1:R), :),1));

			%Mask of lost bilinear terms corresponding to the lost linear terms.
			LostB		 = KeptE & MASK;
			KeptE		 = KeptE(logical(1-MASK));

			%Remove the pruned endmembers from the model and remove corresponding proportions.
			MPlus		 = MPlus(:,logical(1-pruneIndex(1:R)));
			MPlusC		 = formProducts(MPlus);
			P			 = P(logical(1-MASK), :);
			R			 = R - sum(pruneIndex(1:R));

			%Reset all previously pruned bilinear proportions (optional)
			if (Parameters.resetBilinearOnPrune)
				disp(strcat( 'Resetting Bilinear Terms. Removed ', num2str(sum(LostB(R+1:end))), ' Non-negligible.'));
				KeptE_ALT					 = KeptE;
				FRAC						 = 0.99;
				P							 = P .* FRAC;
				P(logical(1-KeptE_ALT), :)	 = (1-FRAC) / sum(logical(1-KeptE_ALT));
				KeptE						 = logical(ones(size(KeptE)));				
			end
	    end
	end


	%Debug output
	disp(strcat('Iteration ' , num2str(t-1)));
	disp(strcat('Least Squares Error = ', num2str(ERR_CUR)));
	disp(strcat('Endmembers Changed By = ', num2str(DIFF)));
	disp(strcat('# of Endmembers = ', num2str(sum(KeptE(1:R))), ' Linear & ', num2str(sum(KeptE(R+1:end))), ' Bilinear'));

	%Save results
	if (mod(t,100) == 99)
		disp('Saved Results');
		save('Solution_Temp.mat', 'P', 'MPlus');
	end
	ERR_TMP = ERR_CUR;
end

%Arrange the result into a struct
SolutionStruct.extra.theta				 = cell([N 1]);
SolutionStruct.endmembers				 = MPlus;
SolutionStruct.endmembers_cross			 = MPlusC;
SolutionStruct.extra.initial_endmembers	 = Parameters.initial_endmembers;
SolutionStruct.extra.initial_props		 = Props;
SolutionStruct.props					 = P;
SolutionStruct.debug.error_array		 = ERR_ARRAY;
SolutionStruct.debug.iterations_used	 = length(ERR_ARRAY);
SolutionStruct.pruned					 = logical(1 - KeptE);

for i=1:N
	SolutionStruct.extra.gammaMatrix{i}	 = GammaFromTheta(P(:,i), R);
	SolutionStruct.extra.theta{i}		 = P(:,i);
	SolutionStruct.extra.alpha{i}		 = P(1:R,i);
	SolutionStruct.extra.beta{i}		 = P(R+1:end,i);
end
SolutionStruct.least_squares_error		 = LSErr_org(Data, P, [MPlus MPlusC]);
SolutionStruct.objective_function		 = LSErr(Data, P, [MPlus MPlusC], Parameters.u, R, KeptE);
SolutionStruct.parameters				 = Parameters;

figure(); plot(ERR_ARRAY); title('Objective Function Value over Time');
end

%A function to estimate the endmembers using derived BISPICE formula.
function [E UP] = Estimate_E(E, P, Data, Params, KeptE, UP)
	u			 = Params.u;
	[D R]		 = size(E);
	Gamma_Mask	 = GenerateMasks(R);
	[R2 N]		 = size(P);
	PM			 = randperm(R);
	M			 = R;

	% Update each endmember as a function of the other endmembers.
	% Order of endmember update is random.
	for k2=1:R
		k			 = PM(k2);
		E(:,k)		 = zeros([D 1]);
		E_FULL		 = [E, formProducts(E)];
		
		GammaB		 = P(Gamma_Mask(k,:), :);
		GammaB		 = [GammaB(1:(k-1),:) ; zeros(1,N) ; GammaB(k:end,:)];
		muNK		 = (repmat( P(k,:) , [D 1]) + E*GammaB);

		% See relevant equations in the accompanying document.
		S_k			 = (u / (M*(M-1))) * sum(E,2);
		E_k			 = (1-u)/N * sum( muNK .* (Data - E_FULL*P) , 2);
		W_k			 = (1-u)/N * sum((muNK).^2 ,2) + ones([D 1]) * (u / M);

		E(:,k)		 = (1 ./ W_k) .* ( S_k + E_k);
	end

end

%Helper methods follow
function G = GammaFromTheta(theta0,R)
u=1;
for i=1:R-1
    for j=i+1:R
        Gam_sq(i,j)=theta0(R+u);
        u=u+1;
        Gam_sq(j,i)=Gam_sq(i,j);
    end
end
G = Gam_sq;

end

%Calculate the objective function
function ERR = LSErr(Data, P, E, u,R, KeptE, UpdateE)
	[D N] = size(Data);
	
	ERR_n = zeros([N 1]);
	ERR = 0;

	ERR_n2 = E*P - Data;
	ERR_n = sum(ERR_n2.^2,2);

	M = sum(KeptE(1:R));
	ERR_r = 0;
	%Only include unpruned endmembers in the objective.
	for i=1:(R-1)
		for j=(i+1):R
			if (~KeptE(j) || ~KeptE(i)) continue; end;
			ERR_r = ERR_r + (E(:,i) - E(:,j))' * (E(:,i) - E(:,j));
		end
	end
	ERR = (1-u) * sum(ERR_n)/N + (u) * ERR_r / (M*(M-1));
end

%Included for debugging purposes.
function ERR = LSErr_org(Data, P, E)
	[D N] = size(Data);
	ERR_n = zeros([N 1]);
	ERR = 0;
	for n=1:N
		ERR_n2	 = E*P(:,n) - Data(:,n);
		ERR_n(n) = ERR_n2' * ERR_n2;
	end

	
	ERR = sum(ERR_n)/N;
end

function M = formProducts(M2)
	[D R] = size(M2);
	M = zeros(D, R*(R-1)/2);
	k = 1;
	for i=1:(R-1)
		for j=(i+1):R
			M(:,k)	 = M2(:,i) .* M2(:,j);
			k		 = k+1;
		end
	end
end

function MASK = GenerateMasks(R)
	MASK = zeros(R,R*(R-1)/2);
	u=R+1;
	for i=1:R-1
	    for j=i+1:R
        	MASK(i,u)	 = 1;
			MASK(j,u)	 = 1;
        	u			 = u+1;
	    end
	end
	MASK = logical(MASK);

end
