#!/bin/bash
# WRF/WPS environment — GNU GCC 13.3.0

# Spack installation prefixes
export NETCDF_C=$(spack location -i /wo7sxq4)
export NETCDF_FORTRAN=$(spack location -i /ppitalu)
export JASPER_ROOT=$(spack location -i /j7r7tlc)
export JASPERLIB="$JASPER_ROOT/lib"
export JASPERINC="$JASPER_ROOT/include"

# WRF source directory
export WRF_DIR="$HOME/WRF"

# Combined netCDF directory created for WPS
export NETCDF="$HOME/WRF-netcdf"
export NETCDFF="-lnetcdff"

# Load GNU-built OpenMPI
spack load /pi2e63d

# Shared library search paths
export LD_LIBRARY_PATH="$NETCDF_C/lib:$NETCDF_FORTRAN/lib:$JASPER_ROOT/lib:${LD_LIBRARY_PATH:-}"

# Enable large-file support
export WRFIO_NCD_LARGE_FILE_SUPPORT=1

echo "WRF/WPS GNU environment loaded."
echo "GFortran: $(gfortran --version | head -1)"
echo "MPI: $(which mpif90)"
echo "netCDF-C: $NETCDF_C"
echo "netCDF-Fortran: $NETCDF_FORTRAN"
echo "JasPer: $JASPER_ROOT"
