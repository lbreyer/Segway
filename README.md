# Segway
ECE 551 Final Design Project: “Segway” like device

Project Implementation Description:
We will be implementing the controls of a “Segway” like device. The device has two motors that can drive
the left and right wheels independently forward or reverse at various speeds. An inertial sensor is used to
obtain the pitch of the platform. If the platform is pitching forward the motors are driven forward to
correct the balance. If the platform is pitching backwards the motors are driven in reverse. There are
load cells in the floor to determine the presence and side to side balance of the rider. A slide
potentiometer on the handle of the device is used to effect steering. Battery voltage and PWM duty cycle
are monitored and used to give audible warnings via a piezo element. Finally authentication of the rider is
achieved via entering a code with their phone via Bluetooth Low Energy

Module Descriptions:

Auth_blk (Authorized Rider):
- An authorized rider will carry a phone with an app that sends the proper authorization code to a BLE
module on the “Segway” device. The Segway control board has a BLE121LR module on that will be
advertising a “Segway” service. When the users phone scans the service, connects, and sends the
appropriate authorization code it will cause the BLE121LR module to send out 0x67 (‘g’) over its
UART TX line. This will in turn cause the pwr_up signal to be asserted.
- When the phone app deliberately disconnects, or is disconnected due to range the BLE121LR
module sends out 0x73 (‘s’) over its UART TX line . The “Segway then shuts down (if the weight on
the platform no longer exceeds MIN_RIDER_WEIGHT (rider_off signal from en_steer block).
- The UART will send at 19200 using 8N1 variant
- Of course once the “Segway” is enabled it will stay enabled as long as there is a rider on the device.
We wouldn’t want it to power down and throw the rider just because the phone went dead or the
BLE link was interrupted. We have a signal (rider_off) that indicates the weight on the platform
does not exceed the minimum allowed rider weight.
- AUTH_blk will be constructed from a UART receiver (UART_rcv) and a
simple state machine comparing the receptions to 0x67, 0x73, and monitoring
the rider_off signal.
- pwr_up is asserted upon reception of ‘g’ (0x67). It is deasserted after
the last reception was ‘s’ and the rider_off signal is high.

UART (RS-232):
- RS-232 signal phases
- Idle
- Start bit
- Data (8-data for our project)
- Parity (no parity for our project)
- Stop bit – channel returns to idle condition
- Idle or Start next frame

- Receiver monitors for falling edge of Start bit. Counts off 1.5 bit times and
starts shifting (right shifting since LSB is first) data into a register.
- Transmitter sits idle till told to transmit. Then will shift out a 9-bit (start bit
appended) register at the baud rate interval.

piezo_drv:
- The Piezo element is used to provide warnings.
- Warning to people in vicinity when rider on
- Warn rider when going too fast
- Warn rider when battery is getting low
- 3 Signals come to piezo to inform of various conditions.
- Drive to piezo is simply digital square wave, and its complement.
- Piezo will respond to signals in the 300Hz to 7kHz range
- A piezo bender is a “speaker” that can be driven with the
GPIO’s of our FPGA. We simply drive with a square
wave of the frequency we want to generate a tone for.

SPI:
- Simple uni-directional serial interface (Motorola long long ago)
- Serial Peripheral Interconnect (very popular physical interface)
- 4-wires for full duplex
- MOSI (Master Out Serf In) (digital core will drive this to AFE)
- MISO (Master In Serf Out) (not used in connection to AFE digital pots, only EEP)
- SCLK (Serial Clock)
- SS_n (Active low Serf Select) (Our system has 4 individual serf selects to
address the 4 dual potentiometers, and a fifth to address the EEPROM)
- We use a 16-bit SPI packet. The master is changing MOSI on the falling edge of
SCLK. The serf device (6-axis inertial sensor or A2D converter) changes MISO on the falling edge
too. We sample MISO on the rising edge.
- SCLK frequency will be 1/16 of the 50MHz clock

A2D Converter (National Semi ADC128S022):
- The DE0 Nano board contains a 12-bit eight
channel A2D converter. We will make use of 3
channels.
- Channels 0 and 4 are used to measure the left
and right load cells respectively. These
readings are used to determine rider
weight/presence and side to side balance.
- Channel 5 reads a slide potentiometer mounted
on the handle the the rider uses for steering
- Channel 6 is a measure of the
Battery voltage and will cause
an audible tone change in
piezo_drv if too low.
- To read the A2D converter one sends the 16-bit packet
{2’b00,chnnl,11’b000} twice via the SPI. There needs to be a
1 system clock cycle pause between the first SPI transaction
completing, and the second one starting
- During the first SPI transaction the value returned over MISO will be ignored. The first 16-bits are
really setting up the channel we wish the A2D to convert. During the 2nd SPI transaction the data
returned on MISO will be the result of the conversion. Only the lower 12-bits are meaningful since it is
a 12-bit A2D.
- The digital core will request A2D readings in a round robin fashion on the four channels. One reading
will be requested every update from the inertial sensor

Inertial Sensor Interface:
- One of the primary functions of the inertial interface is to drive the SPI
interface to configure and perform reads of the inertial sensor.
- Unlike the A2D which requires two 16-bit transactions to complete a single
conversion with the inertial sensor reads/writes are accomplished with single 16-bit
transaction.
- For the first 8-bits of the SPI transaction, the sensor is looking at MOSI to see what
register is being read/written. The MSB is a R/W bit, and the next 7-bits comprise
the address of the register being read or written.
- If it is a read the data at the requested register will be returned on MISO during the 2nd 8-bits of the SPI transaction
- During a write to the inertial sensor the first 8-bits specify it is a write and the
address of the register being written. The 2nd 8-bits specify the data being
written
- After reset de-asserts the system must write to some registers to configure the
inertial sensor to operate in the mode we wish. 
- 0x0D02 Enable interrupt upon data ready
- 0x1053 Setup accel for 208Hz data rate, +/- 2g accel range, 50Hz LPF
- 0x1150 Setup gyro for 208Hz data rate, +/- 245°/sec range.
- 0x1460 Turn rounding on for both accel and gyro
- The table below specifies the addresses used to read inertial data.
- 0xA2xx pitchL ➔ pitch rate low from gyro
- 0xA3xx pitchH → pitch rate high from gyro
- 0xACxx AZL ➔ Acceleration in Z low byte
- 0xADxx AZH ➔ Acceleration in Z high byte

Gyro Reading Integration (and drift):
- The Pitch readings we obtain from the gyro are not an angle, but
rather an angular rate (we get °/sec). Therefore we have to integrate
to get degrees of rotation.
- The small offset will be integrated over time and the reading obtained
purely by integrating the gyro pitch readings will drift. We need to
“fuse” the gyro readings with accelerometer readings (AZ) to correct
for this drift.

Inertial Integrator:
- On every vld pulse this unit will integrate ptch_rt_comp signal into ptch_int[26:0]
(we integrate the negative of ptch_rt_comp due to orientation of sensor mount)
- Bits [26:11] of ptch_int form ptch[15:0] (i.e. divide by 2^11). This scaling factor
was derived by trial and error with the actual Segway.
- There is also a fusion correction term (fusion_ptch_offset) that is summed into
ptch_int.

Sensor Fusion:
- Accelerometers are noisy, and Gyros are subject to long term drift.
- Accelerometer readings are noisy (vibrations and linear acceleration)
- Gyro readings are amazingly quiet (even in presence of vibration) but since
we are integrating, any remaining offset error will result in a long term drift.
- Sensor fusion is an attempt to take the best from each to create a low noise, no drift
version of pitch.
- The fusion data is dominated by the integrated gyro readings, thus it stays low
noise.
- However, pitch is also calculated via accel readings, and the long term
average of the integrated gyro readings is “leaked” toward the accelerometer
results. In electrical engineering terms the accelerometer gets to establish the
DC operating point, but the gyro readings determine the transient response.
- AZ [15:0] will be used to calculate the pitch as seen by the accelerometer
(ptch_acc). If ptch_acc>ptch then ptch_int will have a constant added to it.
If ptch_acc<ptch then ptch_int will have a constant subtracted from it.

Balance Control PID:
- The control input (motor duty cycle and direction in our case) is based
on a combination of terms. One term Proportional to the error. One
term that is the Integral of the error over time, and one term that is
proportional to the Derivative of the error term.

PID (Soft Start Timer):
- The PID unit will also generate the soft start timer (ss_tmr[7:0]) that
is used in SegwayMath to ensure on power up the Segway does not
jerk to a start.
- We want this ramp of ss_tmr to be in the 2-3 second range.
- ss_tmr[7:0] will be formed from the upper 8-bits of a 27-bit timer.
- The FPGA of the Segway is powered and running initially, but it is waiting
for a code from the auth_blk (authorization block) to actually enable the
balancing feature and allow a rider to ride it. When this code comes in via a
Bluetooth link the pwr_up signal will be asserted.
- The counter that forms ss_tmr should be held in a zero state until pwr_up is
asserted.
           
Segway Math (steering input):
- The PID controller ensures the over all forward/reverse drive of the motors to
keep the platform balanced. However, to effect steering a differential signal
is added/subtracted to the left/right motors. This steering signal comes from
a slide potentiometer that the rider controls.
- steer_pot value is clipped to 0x200 to
0xE00, then is converted to a signed
number by subtraction of 12’h7ff. 3/16
of this value is added or subtracted to
13-bit sign extended PID_ss to form
lft_torque/rght_torque if steering is
enabled.
                 
DC Motor Dead Band:
- We will scale/shape our desired torque to compensate
for the DC motors dead zone and compress it into a
small range of desired torques:
(-LOW_TORQUE_BAND,LOW_TORQUE_BAND).
- When: |desired_torque| < LOW_TORQUE_BAND we
are in the steep part of the compensation and will scale
the desired_torque by GAIN_MULTIPLIER (much
greater than unity). When |desired_torque| ≥
LOW_TORQUE_BAND desired_torque will not be
scaled up, but will have MIN_DUTY_CYCLE added
to it if it is positive, or subtracted if it is negative.
- If lft_toque is negative (MSB set) then the compensated torque is:
lft_torque - MIN_DUTY, otherwise it is lft_torque + MIN_DUTY. If the
abs(lft_torque) < LOW_TORQUE_BAND (i.e. we are inside the deadzone)
we need to use lft_torque*$signed(GAIN_MULT) to form the shaped torque.
Finally if the Segway is not powered up we set the shaped torque to zero.

steer_en:

mtr_drv:
- Serves 4 main functions.
1. Synch lft_spd/rght_spd from balance_cntrl to the PWM cycle
2. Convert signed lft_spd/rght_spd to magnitude to drive PWM.
3. Monitor over current signals (OVR_I_lft/OVR_I_right) to perform shut
down if over current occurring too frequently
4. Distribute PWM signals to H-Bridges that drive the motors.
