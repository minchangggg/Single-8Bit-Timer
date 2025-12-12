# [SINGLE 8 BIT TIMER]()
## [Overview]
<img width="70" alt="image" src="https://github.com/user-attachments/assets/0f718b34-c111-49ce-9a1c-70c1e538f0e0">
A fully-synchronous 8-bit timer IP core with APB interface. Supports programmable clock sources, up/down counting modes, and interrupt generation. Designed and verified in Verilog with modular RTL and self-checking testbench.

## [Block diagram]
A Timer Module in its most basic form is a digital logic circuit that counts up or counts down every clock cycle.

<img width="750" alt="image" src="https://github.com/user-attachments/assets/23f72ddf-0e8d-4e1e-9b6f-ae364ec2ef17">

### Register specification
| Offset | Register Name        | Description                 | Bit Width | Access | Reset Value |
|--------|----------------------|-----------------------------|-----------|--------|-------------|
| 0x00   | **TDR** (Timer Data) | Value to load into TCNT     | 8         | R/W    | 0           |
| 0x01   | **TCR** (Control)    | Control signals              | 8        | R/W    | 0           |
| 0x02   | **TSR** (Status)     | Status flags (e.g. overflow) | 8        | R/W    | 0           |
| 0x03   | **TCNT** (Counter)   | Current counter value        | 8        | R      | 0           |

## [Simulation Environment]
<img width="800" alt="image" src="https://github.com/user-attachments/assets/99579b70-6932-4192-976b-384ab6682e23">

### [Test plan]
<img width="1825" height="762" alt="image" src="https://github.com/user-attachments/assets/9ce151a5-7496-4c67-9db8-fda4dec86373" />

## [Simulation Results using Makefile]
<img width="1879" height="528" alt="image" src="https://github.com/user-attachments/assets/0a446a8e-2c00-4867-b93e-4e3c2562fc59" />

<img width="1920" height="988" alt="image" src="https://github.com/user-attachments/assets/fb34e776-e6db-4b97-ab0f-9ceb16bb1f01" />

<img width="1920" height="988" alt="image" src="https://github.com/user-attachments/assets/dc218d1a-bf05-4680-9005-fe590229db95" />
