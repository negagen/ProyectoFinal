#include<stdio.h>
__global__ void interpolate(float * x, float * y, float a, float * k, int n){
    int i,j;
    i = blockIdx.x * blockDim.x + threadIdx.x;

    __shared__ float ss[100], ts[100], ks[100];
    
    if(i<n)
    {
        ss[i]=1;
        ts[i]=1;
        __syncthreads();

        for(j=0;j<n;j++)
        {
            if(j!=i)
            {
                ss[i]=ss[i]*(a-x[j]);
                ts[i]=ts[i]*(x[i]-x[j]);
            }
        }

        ks[i]=(((ss[i])/(ts[i]))*y[i]);
	__syncthreads();
	if(i==0){
	    for(i=0;i<(n*n);i++){
	        *k += ks[i];
	    }
	}
    }
}

int main()
{
    float *x, *y, *d_x, *d_y;
    float a, k, *d_k;  
    size_t size = 100 * sizeof(float);
    cudaEvent_t start, stop;
    
    x = new float[100];
    y = new float[100];
    cudaMalloc(&d_x, size);
    cudaMalloc(&d_y, size);
    cudaMalloc(&d_k, sizeof(float));
    cudaEventCreate(&start);
    cudaEventCreate(&stop);


    int N,i,d=1;
    printf("\n\n Enter the number of the terms of the table: ");
    scanf("%d",&N);
    printf("%d", N);
    printf("\n\n Enter the respective values of the variables x and y: \n");
    for(i=0; i<N; i++)
    {
        scanf ("%f",&x[i]);
        scanf("%f",&y[i]);
    }
    printf("\n\n The table you entered is as follows :\n\n");

    for(i=0; i<N; i++)
    {
        printf("%0.3f\t%0.3f",x[i],y[i]);
        printf("\n");
    }
    cudaMemcpy(d_x, x, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_y, y, size, cudaMemcpyHostToDevice);
    //while(d==1)
    //{
        printf(" \n\n\n Enter the value of the x to find the respective value of y\n\n\n");
        scanf("%f",&a);
	printf("%f\n",a);

	int threads_per_block = 32; // A 16 x 16 block threads
  	int number_of_blocks = N/threads_per_block + 1;
	//dim3 threads_per_block(3, 3); // A 16 x 16 block threads
  	//dim3 number_of_blocks(N/threads_per_block.x + 1, N/threads_per_block.y + 1);
	cudaEventRecord(start);
	interpolate<<<number_of_blocks,threads_per_block>>>(d_x, d_y, a, d_k, N);

        cudaError_t err;
        err = cudaGetLastError(); // `cudaGetLastError` will return the error from above.
        if (err != cudaSuccess)
        { 
            printf("Error: %s\n", cudaGetErrorString(err));
        }
	cudaEventSynchronize(stop);
  	float milliseconds = 0;
  	cudaEventElapsedTime(&milliseconds, start, stop);

	cudaMemcpy(&k, d_k, sizeof(float), cudaMemcpyDeviceToHost);

        printf("\n\n The respective value of the variable y is: %f\n", k);
	printf(" Elapsed time in milliseconds: %f\n", milliseconds);
        printf("\n\n Do you want to continue?\n\n Press 1 to continue and any other key to exit");
        scanf("%d",&d);
    //}

    delete [] x;
    delete [] y;
    cudaFree(d_x);
    cudaFree(d_y);
}
