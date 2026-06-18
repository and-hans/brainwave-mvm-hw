These files were used in EDAPlayground, alongside the UVM testbench, to simulate the MVM engine.

- accum.sv, mem.sv, and ctrl.sv are the same as orignal 
- mvm.sv updates the DOT_STAGE parameter to 9 instead of 8, since multiper updated to use a 4-stage pipeline to resolve timing bottlenecks
- dot8.sv uses a custom dsp_mult module that mimics the original dsp_mult modules function. But it does this in 4-stages instead of 3-stages. The dot8.sv reflects this change by updating the PIP_DEPTH to be 9 instead of 8
- dsp_mult.sv is the alternative multiplication module. This module is used to make it easier to intertwine with EDAPlayground

