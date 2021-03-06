SEQ - Sequencer
===============================
The sequencer block performs automatic execution of sequenced frames to produce
timing signals. Each frame is started internally or by external trigger and
runs for the user-defined time frame (phase-1) and waits for dead time (phase-2)
before moving to the next frame. Each frame sets the block outputs during
phase-1 and phase-2 as defined by user-configured mask.

The frame starts in a wait phase, where it waits until the configured inputs
meet the configured input conditions. Once these input conditions are met,
phase-1 begins and runs for its configured duration, after this, phase2 begins
and runs for its configured duration. If a frame is set to repeat, the repeat
cycle will set outputs immediately, provided the inputs meet the input
conditions. A value of 0 for frame or table repeat means repeat indefinitely.

The procedure for writing table data is to first write to TABLE_RESET, then
sequentially write four 32 bit values to TABLE_DATA. After a complete
table has been written, the TABLE_LENGTH must be provided. After a TABLE_RST, a
whole table and table length must be provided; this means that you cannot
partially overwrite a table. The TABLE_RST sets the ACTIVE state to 0 and
once the TABLE_LENGTH is provided, if the ENABLE is high, the ACTIVE state is
reset to 1 and the sequencer starts from the beginning of the table.

Parameters
----------
=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
PRESCALE        W   UInt32  Prescalar for system clock
TABLE_LENGTH    W   Uint16  Number of frames in the table
TABLE_CYCLE     W   UInt32  Number of times the table will cycle
TABLE_RST       W   UInt32  | Resets table write address to the beginning of the
                            | table
TABLE_DATA      W   UInt32  Table data to be pushed sequentially to the buffer
TABLE_WSTB      W   UInt32  Number of times data has been written to the table
ENABLE          In  Bit     | Gate input:
                            | - Rising edge: Starts the sequencer state machine
                            | - Falling edge: Stops the state machine and puts
                            |   it into FINISHED state
INPA            In  Bit     Trigger input A
INPB            In  Bit     Trigger input B
INPC            In  Bit     Trigger input C
INPD            In  Bit     Trigger input D
OUTA            Out Bit     Output A
OUTB            Out Bit     Output B
OUTC            Out Bit     Output C
OUTD            Out Bit     Output D
OUTE            Out Bit     Output E
OUTF            Out Bit     Output F
ACTIVE          Out Bit     Sequencer Active Flag
CUR_FRAME       R   UInt32  | Sequencer current frame number value. 0 in
                            | INACTIVE state, 1 indexed in ACTIVE state.
CUR_FCYCLE      R   UInt32  | Sequencer current frame cycle value. 0 in
                            | INACTIVE state, 1 indexed in ACTIVE state.
CUR_TCYCLE      R   UInt32  | Sequencer current table cycle value. 0 in
                            | INACTIVE state, 1 indexed in ACTIVE state.
=============== === ======= ===================================================

Sequencer Frame Composition
---------------------------

=============== ================ ==============================================
Bit Field       Name             Description
=============== ================ ==============================================
[31:0]          REPEATS          Number of repeats(cycles) for the frame
[32:32]         USE_INPA         Input A bit mask for triggering use
[33:33]         USE_INPB         Input B bit mask for triggering use
[34:34]         USE_INPC         Input C bit mask for triggering use
[35:35]         USE_INPD         Input D bit mask for triggering use
[36:36]         INPA             Input A conditions to trigger
[37:37]         INPB             Input B conditions to trigger
[38:38]         INPC             Input C conditions to trigger
[39:39]         INPD             Input D conditions to trigger
[95:64]         PH1_TIME         Phase 1 length in pre-scaled clock ticks
[40:40]         PH1_OUTA         Output A value during phase 1
[41:41]         PH1_OUTB         Output B value during phase 1
[42:42]         PH1_OUTC         Output C value during phase 1
[43:43]         PH1_OUTD         Output D value during phase 1
[44:44]         PH1_OUTE         Output E value during phase 1
[45:45]         PH1_OUTF         Output F value during phase 1
[127:96]        PH2_TIME         Phase 2 length in pre-scaled clock ticks
[46:46]         PH2_OUTA         Output A value during phase 2
[47:47]         PH2_OUTB         Output B value during phase 2
[48:48]         PH2_OUTC         Output C value during phase 2
[49:49]         PH2_OUTD         Output D value during phase 2
[50:50]         PH2_OUTE         Output E value during phase 2
[51:51]         PH2_OUTF         Output F value during phase 2
=============== ================ ==============================================

Normal operation
----------------
Once a table has been written, and the table length provided, the ENABLE input
sets the sequencer in the ACTIVE state. The sequencer cycles through frames and
waits for inputs to meet the pre-configured input requirements before setting
outputs in phase-1 and phase2

.. sequence_plot::
   :block: seq
   :title: Multiple frames, multiple frame and table cycles


Inputs outside of active state
------------------------------
Table data must be written after a write to TABLE_RST, which sets the active
state to 0. This means that any inputs that are received during a table write
action are ignored. Similarly, when the sequencer finishes all frame and table
cycles, it sets the active state to 0, thus any inputs after this will be
ignored.

.. sequence_plot::
   :block: seq
   :title: Writing inputs before a whole frame is written

.. sequence_plot::
   :block: seq
   :title: Writing inputs after sequencer has finished

Sequencer and table reset
-------------------------
If the sequencer is set to an inactive state, and then reset to active, the
sequencer will start from the beginning of the table.

.. sequence_plot::
   :block: seq
   :title: Setting inactive before finished and restarting

A table reset and data write must provide a whole table. If a table is currently
written with multiple frames, and a table reset and write overwrites the table
with less frames, only the new table will be executed. It is not possible to
partially overwrite a table.

.. sequence_plot::
   :block: seq
   :title: Reset table and write more data


If the gate signal is re asserted to high after completion, the sequencer will
restart.

.. sequence_plot::
   :block: seq
   :title: Gate dropped on completion, re-raised for re-execution of same frame table
