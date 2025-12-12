# [SINGLE 8 BIT TIMER]()
## [Overview]
<img width="70" alt="image" src="https://github.com/user-attachments/assets/0f718b34-c111-49ce-9a1c-70c1e538f0e0">
A fully-synchronous 8-bit timer IP core with APB interface. Supports programmable clock sources, up/down counting modes, and interrupt generation. Designed and verified in Verilog with modular RTL and self-checking testbench.

<p align="center">
  <img src="https://github.com/user-attachments/assets/4286b8ea-ab3d-4dcd-828d-46faa9327473" width="500">
</p>


> Table TMR Input Pins Configuration

<div align="center">

<table>
  <tr>
    <th>Port Name</th>
    <th>Bit Width</th>
    <th>I/O</th>
    <th>Description</th>
  </tr>

  <tr>
    <td><b>CLK_IN[3:0]</b></td>
    <td>4</td>
    <td>Input</td>
    <td>Timer clock sources used for counting (selected by prescaler field in control register).</td>
  </tr>

  <tr>
    <td><b>PCLK</b></td>
    <td>1</td>
    <td>Input</td>
    <td>System clock for the APB interface.</td>
  </tr>

  <tr>
    <td><b>PRESETn</b></td>
    <td>1</td>
    <td>Input</td>
    <td>Asynchronous active-LOW reset for the timer and APB logic.</td>
  </tr>

  <tr>
    <td><b>PSEL</b></td>
    <td>1</td>
    <td>Input</td>
    <td>APB slave select; HIGH during an access to this timer IP.</td>
  </tr>

  <tr>
    <td><b>PWRITE</b></td>
    <td>1</td>
    <td>Input</td>
    <td>APB transfer direction: HIGH = write, LOW = read.</td>
  </tr>

  <tr>
    <td><b>PENABLE</b></td>
    <td>1</td>
    <td>Input</td>
    <td>Indicates second and subsequent cycles of an APB transfer (enable phase).</td>
  </tr>

  <tr>
    <td><b>PADDR</b></td>
    <td>3</td>
    <td>Input</td>
    <td>APB address bus used to select internal registers (TDR, TCR, TSR, …).</td>
  </tr>

  <tr>
    <td><b>PWDATA</b></td>
    <td>8</td>
    <td>Input</td>
    <td>APB write data bus; carries data to the selected register.</td>
  </tr>

  <tr>
    <td><b>PRDATA</b></td>
    <td>8</td>
    <td>Output</td>
    <td>APB read data bus; returns data from the selected register.</td>
  </tr>

  <tr>
    <td><b>PREADY</b></td>
    <td>1</td>
    <td>Output</td>
    <td>APB ready signal; LOW can extend transfer, HIGH completes transfer.</td>
  </tr>

  <tr>
    <td><b>PSLVERR</b></td>
    <td>1</td>
    <td>Output</td>
    <td>Error indication for an APB transfer (invalid address or write to read-only register).</td>
  </tr>

  <tr>
    <td><b>TMR_OVF</b></td>
    <td>1</td>
    <td>Output</td>
    <td>Timer overflow flag: asserted when counter counts up from <code>8'h00</code> to <code>8'hFF</code>.</td>
  </tr>

  <tr>
    <td><b>TMR_UDF</b></td>
    <td>1</td>
    <td>Output</td>
    <td>Timer underflow flag: asserted when counter counts down from <code>8'hFF</code> to <code>8'h00</code>.</td>
  </tr>

</table>

</div>

## [Block diagram]
A Timer Module in its most basic form is a digital logic circuit that counts up or counts down every clock cycle.

<p align="center">
  <img src="https://github.com/user-attachments/assets/23f72ddf-0e8d-4e1e-9b6f-ae364ec2ef17" width="750">
</p>

### Register specification
<div align="center">

<table>
  <tr>
    <th>Offset</th>
    <th>Register Name</th>
    <th>Description</th>
    <th>Bit Width</th>
    <th>Access</th>
    <th>Reset Value</th>
  </tr>
  <tr>
    <td>0x00</td>
    <td><b>TDR</b> (Timer Data)</td>
    <td>Value to load into TCNT</td>
    <td>8</td>
    <td>R/W</td>
    <td>0</td>
  </tr>
  <tr>
    <td>0x01</td>
    <td><b>TCR</b> (Control)</td>
    <td>Control signals</td>
    <td>8</td>
    <td>R/W</td>
    <td>0</td>
  </tr>
  <tr>
    <td>0x02</td>
    <td><b>TSR</b> (Status)</td>
    <td>Status flags (e.g. overflow)</td>
    <td>8</td>
    <td>R/W</td>
    <td>0</td>
  </tr>
  <tr>
    <td>0x03</td>
    <td><b>TCNT</b> (Counter)</td>
    <td>Current counter value</td>
    <td>8</td>
    <td>R</td>
    <td>0</td>
  </tr>
</table>

</div>

## [Simulation Environment]
<p align="center">
  <img src="https://github.com/user-attachments/assets/99579b70-6932-4192-976b-384ab6682e23" width="800">
</p>

## [Test plan]
<img width="1825" height="762" alt="image" src="https://github.com/user-attachments/assets/9ce151a5-7496-4c67-9db8-fda4dec86373" />

## [Simulation Results using Makefile]
<img width="1879" height="528" alt="image" src="https://github.com/user-attachments/assets/0a446a8e-2c00-4867-b93e-4e3c2562fc59" />

<img width="1920" height="988" alt="image" src="https://github.com/user-attachments/assets/fb34e776-e6db-4b97-ab0f-9ceb16bb1f01" />

<img width="1920" height="988" alt="image" src="https://github.com/user-attachments/assets/dc218d1a-bf05-4680-9005-fe590229db95" />
