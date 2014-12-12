/*! \file cuTFMv4007.cu 
 * \brief ZISC main entry point file
 * this file links cuTFM, coeffGen and FMCSim into a single executable
 */

// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 
// == ZISC cuTFM - main entry point file
// == version v4007
// == Author: Jerzy Dziewierz
// == Centre for Ultrasonic Engineering, University of Strahclyde
// == 2008-2012
// == Internal use only, do not release
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 


// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
// == Main page for the Doxygen automatically generated documentation
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

/*! \mainpage Welcome to the ZISK
 *
 * \section intro_sec What is this?
 * This is an automatically generated document. It contains a readable form of comments that are normally placed in the source code.
 * 
 * There won't be much basic explanations here, but rather advanced for people who are actually interested in hacking the source code. No free lunch!
 *
 * Please see the file list for basic introduction to what's in the box.
 * \section history History of the name
 * 
 * The original name was supposed to be Strais (Strathclyde Imaging System) but that sounds too much like "strata" (loss) in Polish . . . so I had to quickly come up with something else. Now "ZISK" sounds nearly like "gain" in Polish, that's a clearly a better name!
 *
 * Jerzy Dziewierz, University of Strathclyde
 * Copyright 2009-2013
 *
 */

// cuTFM v4007.cu
// entry point file for cuTFM system

// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
// == system wide libraries
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

// Matlab libraries
#include "matrix.h"
#include "mex.h"

// C libraries
#include "omp.h"
#include "math.h"
#include "float.h"
#include "limits.h"


// CUDA libraries
#include "cuda.h"
#include "cuda_runtime.h"
#include "math_constants.h"

// THRUST libraries
#include <thrust/device_ptr.h>
#include <thrust/fill.h>




// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
// == Build related constants
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=


// debug option: force persistent_deviceCount to 1
// #define DEBUG_FORCESINGLEGPU       

// max no. of tx/rx elements, this limits coeff table size
#define max_tx 170
#define max_image_size 4*4096
#define max_devicecount 8
#define FIRSTDEVICE 0 // can be used to limit number of devices used

// there is 5 coefficients per tx-line pair, 5 or 8 is a good number
// 5 for higher performance, 7 for higher accuracy, up to 16 are supported
// note that tests show that it's the simplex descent fminsearch that is inaccurate and unstable, 
// using more than 5 coefficients will rarely result in actually better timing accuracy
// NOTE: less than 5 coeffs not supported (could be if need arises)
#define COEFF_SIZE 5

// if this is defined, linear interpolation is used for picking up values from FMC.
// otherwise the propagation time is truncated to nearest lower integer sample (that's faster)
#define USE_FMC_LINEAR_INTERPOLATION
// #define USE_FMC_NEAREST_SAMPLE

// if this is defined, an older, slower version of fminsearch is used
// if this is undefined, newer, GPU-optimised version of fminsearch is used
#define USE_CLASSIC_FMINSEARCH 

// if this is defined, CPU TimePoint generation path is used
// if this is undefined, GPU path is used
 #define USE_CPU_TimePointGenerator

// allowable fit error for the coeff generator
#define COEFFGEN_ALLOWABLE_FITERROR 1e-8

// coeffgen_nTimePointsPerLine constant that says how many time points to generate
// note that for 5 coeffs, 10+9 would be enough
// for 8 coeffs, 17+16 are required 
// this means 17 are used for coeff fit and 16 are used to verify the error bound
// Note that the polyfit17x* require 17 points and will not work with different number of points
#define COEFFGEN_nTimePointsPerToFit 17
#define COEFFGEN_nTimePointsPerToCheck 16

// note the fit and eval points are interleaved : F E F E F
// F is best to be odd because this gives better stability for polyfit* routines
// E can be F-1 and currently is, see comments near 'fitcheckZ', 'fitinput'
// Total time points per line is F+E
// will drop silent errors if this is not the case
#define COEFFGEN_nTimePointsPerLine 33

// if the RESPECT_DIRCOSLIMIT, there is additional code in the RenderTFMImage that disables accumulation of FMC sample if the cosine of the angle between z axis and line from the tx to rx is lower than ProbeDirectivityCosLimit
// note that this incurs approx. 0.83x  performance pentality, so unless you are sure you need it, it's best to be left disabled
#define RESPECT_DIRCOSLIMIT


// define the initial spread of the simplex for the CUDA-ized simples minimalisation procedures
// used in polyfit_classicMinSearch and polyfit_LockStepMinSearch
/*! \brief Spread for the initial simplex
 *
 * This spreads initial simplex vertices so that the problem space gets explored
 */
#define classicMinSearch_spread 1e-3 


// this will allow nx!=1 when storing scene settings - use with care
#define ALLOW_NX_NONUNITY    

// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
// == system wide re-useable data structures
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

#define pi 3.14159265358979323846f

struct sCFParam
{
    float x1,y1,z1,x2,y2,z2; // position of source and target point
    float slow1,slow2;       // slowness of wave in medium 1 and 2
    float c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14; // parameters of surface for parametric surface    
};


// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
// == Probe description data
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=


// this is a table that gets alocated in GPU constant memory, meaning fast access to these
__constant__ float constant_ProbeElementLocations[3*max_tx]; 

static unsigned int persistent_ProbeElementLocations_buflength=0; // element locations are still needed to calculate dir-cosine 
static float *persistent_ProbeElementLocations=NULL; // for CPU workspace storage

static unsigned int persistent_ProbeElementCount=0; // number of elements in array.

// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
// == Source data tables and metadata
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

static float persistent_FMCSamplingRate;
static float persistent_FMCTimeStart;
static float persistent_ProbeDirectivityCosLimit; // parameter for TFM algorithm
static float persistent_ProbeDirectivityCosPower; // parameter for FMC generation

static unsigned int persistent_TxRxList_length=0; // number of A-scans in FMC. Does not have to match number of elements in the array.
static unsigned int persistent_t_idx_max=0; // sample count of FMC data in each line

// area to store raw FMC Data. 
static float *persistent_multidevice_FMCData[max_devicecount]; 
static unsigned int persistent_FMCDataSizeAllocated[max_devicecount]; // indicates how much data has been allocated, 0 if unallocated, check each time to verify that correct amount is allocated
// description of a-scans
static unsigned char *persistent_multidevice_TxRxList[max_devicecount]; 
static unsigned int persistent_TxRxListSizeAllocated[max_devicecount];
// !! use constant memory symbol to access TxRxList
__constant__ unsigned char constant_TxRxList[2*max_tx*max_tx];

// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
// == Output image data and metadata
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=


static float persistent_x0,persistent_y0,persistent_z0;
static float persistent_dx,persistent_dy,persistent_dz;
static unsigned int persistent_nx,persistent_ny,persistent_nz;

static float *persistent_multidevice_TFMData[max_devicecount]; // pointers to buffers for persistent TFM images to stay on GPU
static unsigned int persistent_TFMDataSizeAllocated[max_devicecount];  // indicates how much data has been allocated, 0 if unallocated, check each time to verify that correct amount is allocated

// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 
// Surface data
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

static float persistent_c0, persistent_c1, persistent_c2, persistent_c3, persistent_c4, persistent_c5, persistent_c6, persistent_c7, persistent_c8, persistent_c9, persistent_c10, persistent_c11, persistent_c12, persistent_c13, persistent_c14;

// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 
// GPU related performance configuration options
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

static float persistent_performance_lastKernelTime;
static unsigned int persistent_performance_xblocksize=256;
static unsigned int persistent_performance_yblocksize=1; // also governs number of coeff lines loaded by the thread block when pre-caching coefficients

// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 
// == Coeff algorithm data - consumers
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

static float *persistent_multidevice_RefractionCoeffData[max_devicecount];
static unsigned int persistent_RefractionCoeffDataSizeAllocated[max_devicecount]; // to check for correct allocation on each GPU 

// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 
// == Coeff algorithm data - generators
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 

/*! \brief persistent surface type specifier
 *
 * 0 for no refraction
 * 1 for flat z=0
 * 2 for an x-centered cylinder - Tim's case
 * 7 - dual/split polynomial surface, extruded in X direction, and Y is the coordinate for the polynomials. 
 */
static int coeffGeneratorSurfaceId=0;


//static float *persistent_HostCoeffBuffer; // for testing only, to be removed later

// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 
// == Misc configuration, internal state keeping, and debugging
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 


// MEX call style option
// Object caller places object pointer as first argument, then firstArgument=1;  (points to 2nd argument of the call)
// if the caller is direct, then methodID is the first argument and firstArgument=0; ( points to 1st argument)
static int persistent_firstArgument=0; // used to indicate if the caller is direct or object. 

static int persistIsInited=0;
static int persistent_params_stored=0; // in particular, image size and probe elements have been stored
static int persistent_coeffs_stored=0; // coeff table has been either stored or generated
static int persistent_deviceCount=0;
static int persistent_verbosemode=0;
static int persistent_debugvariable1=0;



// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 
// == Local libraries
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 

#include "util\cuda_error_check.cu"
#include "util\v4007_method_freeDeviceMemory.cu"
#include "util\v4007_mexExitFunctionHere.cu"
#include "util\v4007_method_query_CUDA.cu"

#include "util\v4007_method_setDebugVariables.cu"
#include "util\v4007_method_get_performance_counter.cu"

// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 
// == TFM Methods
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 

// note that v4007_method_store_params.cu stores image params, probe params, and allocates TFM image buffer. Coeffs are uploaded using method_uploadCoeffs
#include "TFM\v4007_method_store_scene_settings.cu"
#include "TFM\v4007_method_uploadFMC.cu"
#include "TFM\v4007_kernel_RenderTFMImage.cu"
#include "TFM\v4007_method_RenderTFMImage.cu"
#include "TFM\v4007_method_downloadImage.cu"


#include "TFM\v4007_method_setGPUPerformanceOptions.cu"
#include "TFM\v4007_method_uploadCoeffs.cu"


// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 
// == Coeff generator Methods
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 

#include "CoeffGenerator\v4007_method_downloadCoeffs.cu"
#include "CoeffGenerator\polyfit_classicMinSearch.cu"
#include "CoeffGenerator\polyfit_LockStepMinSearch.cu"
#include "CoeffGenerator\polyfit_helper.cu"
#include "CoeffGenerator\polyfit17x3.cu"
#include "CoeffGenerator\polyfit17x4.cu"
#include "CoeffGenerator\polyfit17x5.cu"
#include "CoeffGenerator\polyfit17x6.cu"
#include "CoeffGenerator\polyfit17x7.cu"

// include surface functions and CF (CostFunction) Launchers
#include "CoeffGenerator\polyfit_FlatZ.cu"
#include "CoeffGenerator\polyfit_CylnX.cu"
#include "CoeffGenerator\polyfit_SinX.cu"
#include "CoeffGenerator\polyfit_Poly5.cu"
#include "CoeffGenerator\polyfit_DualPolySurface.cu"

// method to evaluate what the points on the surface are
#include "CoeffGenerator\GetSurface.cu"

#include "CoeffGenerator\ind2sub.cu"
#include "CoeffGenerator\v4007_kernel_GenerateTimePoints.cu"
#include "CoeffGenerator\v4007_method_GenerateTimePoints.cu"
#include "CoeffGenerator\v4007_method_GenerateCoeffs.cu"

// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 
// == FMC generator
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 
#include "FMCSim\v4007_method_ResetFMC.cu"
#include "FMCSim\v4007_method_DownloadFMC.cu"

#include "FMCSim\v4007_kernel_GenerateFMC.cu"
#include "FMCSim\v4007_method_GenerateFMC.cu"

// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 
// == Basic Licence check
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 
#include "cuTFMv4007_LicenceCheck.cu"

       
 
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 
// == Some old documentation that i am attached to
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 

// cuTFM: the code kernel that runs on the graphics card
// it is called in "in parallel" for each output pixel.
// note that the output size is assumed to be aligned with the block dimensions!
// this is a strong assumption but i have made it for performance reasons 
//- it is faster to calculate a bit more pixels than for each pixel check 
// if it should be calculated or not. It saves on thread diveregence.
// parameters: 
// x0,y0 - starting coordinates of the result image. 
// dx,dy - spatial steps of the result image (distance between pixels)
// nx,ny - number of pixels in the result image(size of the output array)
//          the pixel coordinates to create image for are calculated 
//          on the fly depending on the built-in thread identifiers 

// NOTE: NAMING CONVENTION
// "*TX" means "current transmiting element of the probe" 
// "*RX" means "current receiving element of the probe"
// "i*" means integer iterator or counter
// "n*" means iteration limit/total count
// "d*" means distance/step size/resoulution
// "*x" and "*y" means on x,y axis respectively

// note that all values are floats(single precision). 
// doubles are supported on newer cards, but they are much slower! 
// single precision should be precise enough for our purpose 
// - 23 bits of precision+sign, 8bits of expotent makes "32-bit single"


// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 
// == mexFunction
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 

// mexFunction: Entry point for matlab. This is what matlab calls.
// for complete and exhaustive documentation see 
// http://www.mathworks.com/support/tech-notes/1600/1605.html#mexFunction

/*! \fn void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
 * \brief Main entry point for calling from Matlab
 * decides which of the included methods to call and passes controll to selected one
 */
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int methodID;
  int deviceIdx;  
  // attempt to call Matlab function to check if the program is OK to run
       
  // register exit funciton
   mexAtExit(mexExitFunctionHere);
   
  // check if this is first run
   if (persistIsInited==0)
   {
       LicenceCheck();
       mexPrintf("Starting cuTFMv4007 kernel. Jerzy Dziewierz, CUE 2008-2012\n");
       // initialize persistent_multidevice_FMCdata to nulls
       cudaGetDeviceCount(&persistent_deviceCount); 
       mexPrintf("%d GPUs detected.\n",persistent_deviceCount); 
       if(persistent_deviceCount == 0){
            mexErrMsgTxt("The current version of this code will fail without any GPUs available.\n");
       }
       // Jurek, I've added the above line for debugging purposes. Feel free to remove.
#ifdef DEBUG_FORCESINGLEGPU       
       //DEBUG CODE: FORCE DeviceCount to 1
       persistent_deviceCount=1;
#endif
       for(deviceIdx=FIRSTDEVICE;deviceIdx<persistent_deviceCount;deviceIdx++)
       {
          persistent_multidevice_FMCData[deviceIdx]=NULL;          
       }       
       persistIsInited=1;
   }
   else
   {
       // nothing special to do if not a first run
   }

// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 
// == Process the inputs
// == *=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*= 
// == Note that there is a change in the way this mex is called when compared to previous version
// == in this version, in order to support calling the mex as a method of an object, the first argument 
// == is expected to be either object (which is natural for functions called from an object) 
// == OR at least a structure that has neccesary properties that this mex requires.    
// == Some legacy code is left here to allow debugging without object present, but this will be modified to object only later on.
   
   // check if there is more than 0 arguments
   if (nrhs==0)
       mexErrMsgTxt("at least 1 input (methodID) required. Try cuTFMv4007(int32(1)) ");
   
   // check if 1st argument is 1x1 uint32, not complex etc.      
   if( !mxIsNumeric(prhs[0]) || mxIsComplex(prhs[0]) ||
            mxGetN(prhs[0]) * mxGetM(prhs[0])!=1 ) 
                { // the first argument is not the MethodID - check 2nd argument
       
                     if (nrhs==1)
                           mexErrMsgTxt("the first parameter is not methodID and there is no 2nd parameter. At least 1 input (methodID) required. Try cuTFMv4007(int32(1)) ");  
                                        
                    // check if argument 2 (index=1) fits the format of methodID
                        if( mxIsNumeric(prhs[1]) && !mxIsComplex(prhs[1]) &&  mxGetN(prhs[1])==1 && mxGetM(prhs[1])==1 ) 
                        {
                         // seems OK
                          persistent_firstArgument=1;
                        }
                }
   else // meaning the 1st argument DOES match the template of methodID
   {
       persistent_firstArgument=0;
   }   
   // ok, get the MethodID value and act upon it
   methodID=(int)mxGetScalar(prhs[persistent_firstArgument]);
   switch (methodID)
   {
     case 0:  mexPrintf("method 0 called - no output\n"); break;
     case 1:  method_query_CUDA(); break;
     case 17: method_get_performance_counter(nlhs,plhs); break;
     
     // note that the below methods are not compatible with v4006, so they have to have higher MethodID numbers
     // general methods
     
     case 19:  method_store_scene_settings(nrhs,prhs); break;     
     case 20:  method_uploadFMC(nrhs,prhs); break;
     case 21:  method_RenderTFMImage(); break;
     case 22:  method_downloadImage(nlhs,plhs); break; 
     case 23:  method_setDebugVariables(nlhs,plhs,nrhs,prhs); break; 
     case 24:  method_setGPUPerformanceOptions(nrhs,prhs); break; 
     
     // coeff generator
     case 25:  method_uploadCoeffs(nrhs,prhs); break;
     case 26:  method_GenerateCoeffs(nlhs,plhs,nrhs,prhs); break;
     case 27:  method_downloadCoeffs(nlhs,plhs); break;
     
     // FMC generator
     case 28: method_ResetFMC(nlhs,plhs,nrhs,prhs); break;
     case 29: method_DownloadFMC(nlhs,plhs,nrhs,prhs); break;
     case 30: method_GenerateFMC(nlhs,plhs,nrhs,prhs); break;
     
     // evaluate surface
     case 31: method_GetSurface(nlhs,plhs,nrhs,prhs); break;
     
     
     // case28: method_doAbsLog(nlhs,plhs);
               
     default: mexPrintf("method %d not implemented or invalid\n",methodID); break;
     
   }
}
 