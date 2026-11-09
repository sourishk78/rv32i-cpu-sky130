import cpu_pkg::*;

module alu (input instr_type_e instr_type_i, input logic [31:0] rs1_data_i, input logic [31:0] rs2_data_i, input logic [31:0] imm_i, input logic [31:0] pc_i, output logic [31:0] result_o, output logic [31:0] mem_addr_o, output logic [31:0] branch_target_o, output logic branch_taken_o);
    always_comb begin
        result_o = 32'd0;
        mem_addr_o = 32'd0;
        branch_target_o = 32'd0;
        branch_taken_o = 1'b0;

        case (instr_type_i)
            //cornell risc website
            ADDI: result_o = rs1_data_i + imm_i;
            ADD: result_o = rs1_data_i + rs2_data_i;
            SUB: result_o = rs1_data_i - rs2_data_i;
            SLL: result_o = rs1_data_i << rs2_data_i[4:0];
            //logic is unsigned by default, so can use <</>>
            SRL: result_o = rs1_data_i >> rs2_data_i[4:0];
            LOAD: mem_addr_o = rs1_data_i + imm_i;
            STORE: mem_addr_o = rs1_data_i + imm_i;
            BEQ: begin
                branch_target_o = pc_i + imm_i;
                branch_taken_o = (rs1_data_i == rs2_data_i);
            end
            default: ;
        endcase
    end
endmodule