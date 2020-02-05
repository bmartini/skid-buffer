# Verilog Skid Buffer

A skid buffer decouples the two sides of a valid/ready handshake so as to allow
the control signals to be registered. When the down stream ready is deasserted
while up stream data is incoming, the buffer will store the incoming up stream
data so it can be released once the down ready is reasserted. This module is
used to improve the timing of a design by registering all signals in a into and
out of the buffer.


## Modules

The *skid_register.v* module has been designed for easy integration and use with
AXI buses or similar. Thus the behavior of the valid/ready bus conforms to AXI
usage. Namely:

* Both __valid__ & __ready__ must be asserted for a successful transfer
* __ready__ must only be deasserted directly after a successful transfer
* __valid__ must only be deasserted directly after a successful transfer
* __valid__ being asserted must not depend on __ready__ also being asserted
* __data__  must be stable while __valid__ is asserted


Additionally, a special case skid buffer named the *skid_fallthrough.v* module
is also provided. It is used with a FIFO to approximate the behavior of a fall
though FIFO while also registering the 'pop' signal before it's passed into the
FIFO. This module is also used to improve timing of a design.


## Formal Verification

Assertions are used to model the behavior of the modules for use in formal
verification. To preform the verification proof the open source software
[SymbiYosys](https://symbiyosys.readthedocs.io/en/latest/).


```bash
sby -f skid_register.sby
sby -f skid_fallthrough.sby
```
