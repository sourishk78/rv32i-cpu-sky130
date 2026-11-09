import cpu_pkg::*;
module decode (input logic [31:0] instr_i, output logic [4:0] rd_o, output logic [4:0] rs1_o, output logic [4:0] rs2_o, output logic [31:0] imm_o, output instr_type_e instr_type_o);
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    localparam OPCODE_OP_IMM = 7'b0010011;
    localparam OPCODE_OP = 7'b0110011;
    localparam OPCODE_LOAD = 7'b0000011;
    localparam OPCODE_STORE = 7'b0100011;
    localparam OPCODE_BRANCH = 7'b1100011;
    localparam OPCODE_SYSTEM = 7'b1110011;

    always_comb begin
        opcode = instr_i[6:0];
        rd_o = instr_i[11:7];
        funct3 = instr_i[14:12];
        rs1_o = instr_i[19:15];
        rs2_o = instr_i[24:20];
        funct7 = instr_i[31:25];
        imm_o = {{20{instr_i[31]}}, instr_i [31:20]};
        instr_type_o = NOP;
        case (opcode)
            OPCODE_OP_IMM: begin
                if (funct3 == 3'b000) begin
                    instr_type_o = ADDI;
                end
            end
            OPCODE_OP: begin
                if (funct3 == 3'b000 && funct7 == 7'b0000000) begin
                    instr_type_o = ADD;
                end
                else if ( funct3 == 3'b000 && funct7 == 7'b0100000) begin
                    instr_type_o = SUB;
                end
                else if (funct3 == 3'b001 && funct7 == 7'b0000000) begin
                    instr_type_o = SLL;
                end
                else if (funct3 == 3'b101 && funct7 == 7'b0000000) begin
                    instr_type_o = SRL;
                end
            end
            OPCODE_LOAD: begin
                if (funct3 == 3'b010) begin
                    instr_type_o = LOAD;
                end
            end
            OPCODE_STORE: begin
                if (funct3 == 3'b010) begin
                    instr_type_o = STORE;
                    imm_o[4:0] = instr_i[11:7];
                    imm_o[11:5] = instr_i[31:25];
                    imm_o[31:12] = {20{instr_i[31]}};
                end
            end
            OPCODE_BRANCH: begin
                if (funct3 == 3'b000) begin
                    instr_type_o = BEQ;
                    //fix, reverting risc b-type template. sorted b-type > original imm
                    imm_o[0] = 1'b0;
                    imm_o[4:1] = instr_i[11:8];
                    imm_o[10:5] = instr_i[30:25];
                    imm_o[11] = instr_i[7];
                    imm_o[31:12] = {20{instr_i[31]}};
                end
            end
            OPCODE_SYSTEM: begin
                if(instr_i[31:20] == 12'h001) begin
                    instr_type_o = EBREAK;
                end
            end
            default: ;
        endcase
    end
endmodule
