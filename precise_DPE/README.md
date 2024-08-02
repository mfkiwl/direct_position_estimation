# Precise DPE

This project is divided into two parts:

- **`theoretical` Folder**:  
  Contains simulations for the Precise DPE (PDPE) approach. Here, we compare the bound and RMSE (Root Mean Square Error) of the standard DPE and the proposed PDPE.  
  <img src="figs/Compare_2SP_C_noC_modified.png" alt="2SP vs DPE vs PDPE" width="600"/>

- **`over_air` Folder**:  
  Contains experiments for PDPE using practical over-the-air signals. The satellite information is obtained using traditional methods via GNSS-SDR.  
  <img src="figs/real_world_pdpe.png" alt="Positioning Performance" width="600"/>

**Note**: In the code, comments, and figures, you may encounter terms like *DPE with C* or *DPE with Carrier Phase*. These terms refer to the proposed PDPE algorithm.