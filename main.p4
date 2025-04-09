#include <core.p4>
#include <xsa.p4>

const bit<16> TYPE_ETH_DIVIDE = 0x88b5;

struct divider_input {
    bit<32> divisor;
    bit<32> dividend;
}

struct divider_output {
    bit<32> remainder;
    bit<32> quotient;
}

// ****************************************************************************** //
// *************************** M E T A D A T A ********************************** //
// ****************************************************************************** //
struct metadata_t {
    // *********************** Custom Metadata ********************************** //
    // NOTE: Sharing user custom metadata between parser/control blocks
    // ...
    // *********************** System Metadata (Do not delete) ****************** //
    bit<9>  egress_port;
    bit<9>  ingress_port;
    bit<16> packet_length;
}

// ****************************************************************************** //
// *************************** H E A D E R S ************************************ //
// ****************************************************************************** //
header ethernet_h {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ether_type;
}

header divide_h {
    bit<32> divisor;
    bit<32> dividend;
    bit<32> remainder;
    bit<32> quotient;
}

struct headers_t {
    ethernet_h ethernet;
    divide_h divide;
}

// ****************************************************************************** //
// *************************** P A R S E R ************************************** //
// ****************************************************************************** //
parser MyParser(
    packet_in packet,
    out headers_t headers,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
) {
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(headers.ethernet);
        transition select(headers.ethernet.ether_type) {
            TYPE_ETH_DIVIDE: parse_divide;
            default: accept;
        }
    }

    state parse_divide {
        packet.extract(headers.divide);
        transition accept;
    }
}

// ****************************************************************************** //
// *************************** P R O C E S S I N G ****************************** //
// ****************************************************************************** //
control MyProcessing(
    inout headers_t headers,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
) {
    UserExtern<divider_input, divider_output>(1) calc_divide;
    divider_input div_in;
    divider_output div_out;

    action drop() {
        standard_metadata.drop = 1;
    }

    apply {
        if (standard_metadata.parser_error != error.NoError) {
            drop();
            return;
        }

        if (headers.divide.isValid()) {
            div_in.dividend = headers.divide.dividend;
            div_in.divisor = headers.divide.divisor;
            calc_divide.apply(div_in, div_out);
            headers.divide.quotient = div_out.quotient;
            headers.divide.remainder = div_out.remainder;
        }

        if (metadata.ingress_port == 0) {
            metadata.egress_port = 8;
        } else {
            metadata.egress_port = 0;
        }
    }
} 

// ****************************************************************************** //
// **************************** D E P A R S E R ********************************* //
// ****************************************************************************** //
control MyDeparser(
    packet_out packet,
    in headers_t headers,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
) {
    apply {
        packet.emit(headers.ethernet);
        packet.emit(headers.divide);
    }
}

// ****************************************************************************** //
// ******************************** M A I N ************************************* //
// ****************************************************************************** //
XilinxPipeline(
    MyParser(),
    MyProcessing(),
    MyDeparser()
) main;
