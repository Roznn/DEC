% Rozenn Dahyot 2022
%
function DEMOPCC

clear all; close all;

%% Read Data / comment as appropriate
% NameOfData='MNISToriginal'  % original split Xtrain 60000 and Xtest 10000
NameOfData='MNIST10'
% NameOfData='wine'
% NameOfData='australian'

[Xtrain,Xtest,Ytrain,Ytest] = fctLoadData(NameOfData);

%% Hyperparameters  0<=0 alpha <=1
if (strcmp(NameOfData,'MNISToriginal'))
    alpha=.9
    ne=16 % ne=1 to 794
elseif (strcmp(NameOfData,'MNIST10'))
    alpha=.9
    ne=16  % ne=1 to 794
elseif (strcmp(NameOfData,'wine'))
    alpha=.4
    ne=4  % ne=1 to 16
    'random allocations train and test sets creating different results at each run'
elseif (strcmp(NameOfData,'australian'))
    alpha=.4
    ne=4  % ne=1 to 16
    'random allocations train and test sets creating different results at each run'
end



%% Data encoding with class
tic
Z=[(1-alpha)*Xtrain;alpha*Ytrain];
Z0=[(1-alpha)*Xtrain;zeros(size(Ytrain))];
Ztest0=[(1-alpha)*Xtest;zeros(size(Ytest))];


%% PCA covariance matrix of Z / principal components

CovZ=Z*Z'/size(Z,2);
[U,S,V] = svd(CovZ);

%% Encoding:  projection in Eigenspace

pZ=U'*Z;
pZ0=U'*Z0;
pZtest0=U'*Ztest0;

% Decoding: reconstruction in z-space
Zhat=U(:,1:ne)*pZ(1:ne,:);
Z0hat=U(:,1:ne)*pZ0(1:ne,:);
Ztest0hat=U(:,1:ne)*pZtest0(1:ne,:);

% extracting subvector for class prediction
Yhat=Zhat(size(Xtrain,1)+1:size(Z,1),:);
Y0hat=Z0hat(size(Xtrain,1)+1:size(Z,1),:);
Ytest0hat=Ztest0hat(size(Xtest,1)+1:size(Ztest0,1),:);

%% computing classification accuracy
'classification accuracy on  training set with class:'
score= fctScore(Yhat,Ytrain)

'classification accuracy on training set without class:'
score0= fctScore(Y0hat,Ytrain)


'classification accuracy on test set  without class:'
scoretest0= fctScore(Ytest0hat,Ytest)

toc

%% figures 1 and 2 in the paper https://arxiv.org/abs/2210.12746

if (strcmp(NameOfData,'MNIST10'))
    
    figure;
    for k=1:4
        subplot(4,2,2*k-1), imagesc(reshape(U(1:784,k), 28, 28)'), colormap('gray'), axis square,colorbar,
        subplot(4,2,2*k), stem(U(785:794,k),'filled'), axis square,
    end
    
    
    [rows,cols,vals] = find(Ytrain==1);
    clr = hsv(size(Ytrain,1));
    for i=2:1:3
          figure;
        gscatter(pZ(i,:),pZ(i+1,:),rows-1,clr), axis square, ...
            title(strcat('Eigenspace ',int2str(i),'and',int2str(i+1)))
    end
end

%%
function [Xtrain,Xtest,Ytrain,Ytest] = fctLoadData(NameOfData)
% [Xtrain,Xtest,Ytrain,Ytest] = fctLoadData(NameOfData)
% Rozenn Dahyot 2022/09/26
%   NameOfData: string 'MNIST10','wine',  'australian'

if (strcmp(NameOfData,'MNIST10'))
    
    d=load('mnist.mat');
    
    TrainingImages = d.trainX;
    LabelTraining=d.trainY;
    
    % Create a balanced Training Set NpC per class
    NpC=double(1000); % nb of images per class
    nc=length(unique(LabelTraining)); % nb of class
    N=nc*NpC; %  total nb of images
    dimimage=784; % feature space dimension
    spacedim=dimimage+nc;
    
    
    Xtrain=zeros(dimimage,nc*NpC);
    Ytrain=zeros(nc,nc*NpC);
    
    Xtest=zeros(dimimage,nc*NpC);
    Ytest=zeros(nc,nc*NpC);
    
    for i=0:nc-1
        Ind=find(LabelTraining==i);
        Xtrain(:,i*NpC+1:(i+1)*NpC)=double(TrainingImages(Ind(1:NpC),:))'/255;
        Ytrain(i+1,i*NpC+1:(i+1)*NpC)=1;
        
        Xtest(:,i*NpC+1:(i+1)*NpC)=double(TrainingImages(Ind(NpC+1:2*NpC),:))'/255;
        Ytest(i+1,i*NpC+1:(i+1)*NpC)=1;
        
    end
    
    
elseif(strcmp(NameOfData,'MNISToriginal'))
    
    d=load('mnist.mat');
    
    
    LabelTraining=d.trainY;
    
    nc=double(max(LabelTraining)-min(LabelTraining)+1); % nb of class
    
    dimimage=size(d.trainX,2); % feature space dimension
    spacedim=dimimage+nc;
    Ntrain=size(d.trainX,1);
    Ntest=size(d.testX,1);
    
    
    Xtrain=double(d.trainX)'/255;
    Xtest=double(d.testX)'/255;
    Ytrain=zeros(nc, Ntrain);
    Ytest=zeros(nc,Ntest);
    
    for i=0:nc-1
        Ind=find(d.trainY==i);
        Ytrain(i+1,Ind)=1;
        Indt=find(d.testY==i);
        Ytest(i+1,Indt)=1;
        
    end
    
    
elseif(strcmp(NameOfData,'wine'))
    
    load('wine.mat');
    X=X';
    for i=1:size(X,1)
        X(i,:)=X(i,:)/max(X(i,:));
    end
    
    P = randperm(size(X,2)); % to change selection for training
    X(:,:)=X(:,P);y=y(P);
    
    NpC=40; % for training per class
    nc=3;
    N=length(X);
    Xtrain=zeros(size(X,1),NpC*nc);
    Ytrain=zeros(nc,NpC*nc);
    
    Xtest=zeros(size(X,1),N-NpC*nc);
    Ytest=zeros(nc,N-NpC*nc);
    
    L=1;
    for k=1:nc
        Ind=find(y==k-1);
        Xtrain(:,(k-1)*NpC+1:k*NpC)=X(:,Ind(1:NpC));
        Ytrain(k,(k-1)*NpC+1:k*NpC)=1;
        
        Xtest(:,L:length(Ind)-NpC+L-1)=X(:,Ind(NpC+1:length(Ind)));
        Ytest(k,L:length(Ind)-NpC+L-1)=1;
        L=L+length(Ind)-NpC;
    end
    
elseif(strcmp(NameOfData,'australian'))
    
    load('australian.mat');
    X=X';
    
    for i=1:size(X,1)
        X(i,:)=X(i,:)/max(X(i,:));
    end
    
    P = randperm(size(X,2));
    X(:,:)=X(:,P);y=y(P);
    
    NpC=200; % for training
    nc=2;
    N=length(X);
    Xtrain=zeros(size(X,1),NpC*nc);
    Ytrain=zeros(nc,NpC*nc);
    
    Xtest=zeros(size(X,1),N-NpC*nc);
    Ytest=zeros(nc,N-NpC*nc);
    
    L=1;
    for k=1:nc
        Ind=find(y==k-1);
        Xtrain(:,(k-1)*NpC+1:k*NpC)=X(:,Ind(1:NpC));
        Ytrain(k,(k-1)*NpC+1:k*NpC)=1;
        
        Xtest(:,L:length(Ind)-NpC+L-1)=X(:,Ind(NpC+1:length(Ind)));
        Ytest(k,L:length(Ind)-NpC+L-1)=1;
        L=L+length(Ind)-NpC;
    end
    
    
end
%%
function scorelabel= fctScore(Yhat,Yref)
% function scorelabel= fctScore(Yhat,Yref)
%   Yhat: estimate/prediction
%   Yref: Reference/ground truth


if (size(Yhat)==size(Yref))
    
    
    [temp,labelhat]=max(Yhat,[],1);
    [temp,labelref]=max(Yref,[],1);
    scorelabel=sum((abs(double(labelhat)-double(labelref)))==0)/ size(Yhat,2);
    
    
else
    
    display('the inputs dont have the same size')
    
    scorelabel=-1;
    
end
