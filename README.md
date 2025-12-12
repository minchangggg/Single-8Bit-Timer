# [SINGLE 8 BIT TIMER]()
## [Overview]
<img width="70" alt="image" src="https://github.com/user-attachments/assets/0f718b34-c111-49ce-9a1c-70c1e538f0e0">
A fully-synchronous 8-bit timer IP core with APB interface. Supports programmable clock sources, up/down counting modes, and interrupt generation. Designed and verified in Verilog with modular RTL and self-checking testbench.

<img width="500" alt="image" src="https://github.com/user-attachments/assets/4286b8ea-ab3d-4dcd-828d-46faa9327473">

> Table TMR Input Pins Configuration

| **Port Name**   | **Bit Width** | **I/O** | **Description**                                                                          |
| --------------- | ------------- | ------- | ---------------------------------------------------------------------------------------- |
| **CLK_IN[3:0]** | 4             | Input   | Timer clock sources used for counting (selected by prescaler field in control register). |
| **PCLK**        | 1             | Input   | System clock for the APB interface.                                                      |
| **PRESETn**     | 1             | Input   | Asynchronous active-LOW reset for the timer and APB logic.                               |
| **PSEL**        | 1             | Input   | APB slave select; HIGH during an access to this timer IP.                                |
| **PWRITE**      | 1             | Input   | APB transfer direction: HIGH = write, LOW = read.                                        |
| **PENABLE**     | 1             | Input   | Indicates second and subsequent cycles of an APB transfer (enable phase).                |
| **PADDR**       | 3             | Input   | APB address bus used to select internal registers (TDR, TCR, TSR, …).                    |
| **PWDATA**      | 8             | Input   | APB write data bus; carries data to the selected register.                               |
| **PRDATA**      | 8             | Output  | APB read data bus; returns data from the selected register.                              |
| **PREADY**      | 1             | Output  | APB ready signal; LOW can extend transfer, HIGH completes transfer.                      |
| **PSLVERR**     | 1             | Output  | Error indication for an APB transfer (invalid address or write to read-only register).   |
| **TMR_OVF**     | 1             | Output  | Timer overflow flag: asserted when counter counts up from `8'h00` to `8'hFF`.            |
| **TMR_UDF**     | 1             | Output  | Timer underflow flag: asserted when counter counts down from `8'hFF` to `8'h00`.         |

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
