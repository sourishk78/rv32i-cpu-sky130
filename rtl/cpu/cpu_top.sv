module cpu_top (
	input logic clk_i,
	input logic rst_i,
	input logic en_i,

	output logic halted_o,

	output logic [31:0] reg_crossbar_o [0:31],

	output logic 	    isram_en_o,
	output logic [9:0]  isram_addr_o,
	input  logic [31:0] isram_rdata_i,
	input  logic 	    isram_rready_i,

	output logic 		dsram_en_o,
	output logic 		dsram_write_en_o,
	output logic [9:0]  dsram_addr_o,
	output logic [31:0] dsram_wdata_o,
	input  logic [31:0] dsram_rdata_i,
	input  logic 	    dsram_rready_i
);

	import cpu_pkg::*;

	// === Signal Declarations === //
	logic stall_core;
	logic [4:0] rd, rs1, rs2;

	// Fetch
	logic [31:0] instr;
	logic [31:0] current_pc;
	logic instr_vld;
	logic branch_vld;
	logic [9:0] branch_trgt;
	logic branch_taken;

	typedef enum logic [2:0] {
		S_WAIT_FETCH,
		S_EXEC,
		S_MEM_WAIT,
		S_WRITEBACK,
		S_ADVANCE
	} states_e;

	states_e states_current;
	states_e states_next;

	assign stall_core = halted_o | ~en_i | ~(states_current == S_ADVANCE);

	// === Instruction Fetch === //
	fetch u_fetch (
		.clk_i(clk_i),
		.rst_i(rst_i),
		.en_i(en_i),
		.stall_core_i(stall_core),
		.isram_en_o(isram_en_o),
		.isram_addr_o(isram_addr_o),
		.isram_rdata_i(isram_rdata_i),
		.isram_rready_i(isram_rready_i),
		.instr_o(instr),
		.pc_o(current_pc),
		.instr_vld_o(instr_vld),
		.branch_vld_i(branch_vld),
		.branch_trgt_i(branch_trgt),
		.branch_taken_i(branch_taken)
	);

	logic [31:0] rs1_data, rs2_data;
	logic [31:0] reg_values [0:31];

	logic rd_write_en;
	logic [4:0] rd_write_addr;
	logic [31:0] rd_write_data;
	assign rd_write_addr = rd;

	reg_file u_reg_file (.clk_i(clk_i), .rst_i(rst_i), .rs1_addr_i(rs1), .rs2_addr_i(rs2), .rs1_data_o(rs1_data), .rs2_data_o(rs2_data), .rd_write_en_i(rd_write_en), .rd_addr_i(rd_write_addr), .rd_data_i(rd_write_data), .reg_values_o(reg_values));
	assign reg_crossbar_o = reg_values;

	logic [31:0] imm;
	instr_type_e instr_type;
	decode u_decode (.instr_i(instr), .rd_o(rd), .rs1_o(rs1), .rs2_o(rs2), .imm_o(imm), .instr_type_o(instr_type));

	logic [31:0] alu_result, alu_mem_addr, alu_branch_target;
	logic alu_branch_taken;
	alu u_alu (.instr_type_i(instr_type), .rs1_data_i(rs1_data), .rs2_data_i(rs2_data), .imm_i(imm), .pc_i(current_pc), .result_o(alu_result), .mem_addr_o(alu_mem_addr), .branch_target_o(alu_branch_target), .branch_taken_o(alu_branch_taken));

	always_ff @( posedge clk_i) begin
		if (rst_i) begin
			states_current <= S_WAIT_FETCH;
		end
		else begin
			states_current <= states_next;
		end
	end

	always_comb begin
		states_next = states_current;
		case (states_current)
			S_WAIT_FETCH: begin
				if (instr_vld) begin
					states_next = S_EXEC;
				end
			end
			S_EXEC: begin
				if (instr_type == LOAD || instr_type == STORE ) begin
					states_next = S_MEM_WAIT;
				end
				else if (instr_type == BEQ) begin
					states_next = S_ADVANCE;
				end
				else begin
					states_next = S_WRITEBACK;
				end
			end
			S_MEM_WAIT: begin
				if (dsram_rready_i) begin
					if(instr_type == LOAD) begin
						states_next = S_WRITEBACK;
					end
					else begin
						states_next = S_ADVANCE;
					end
				end
			end
			S_WRITEBACK: begin
				states_next = S_ADVANCE;
			end
			S_ADVANCE: begin
				states_next = S_WAIT_FETCH;
			end
			default: ;
		endcase
	end

	always_comb begin
		branch_vld   = 1'b0;
		branch_trgt  = '0;
		branch_taken = 1'b0;
		if (states_current == S_ADVANCE && instr_type == BEQ) begin
			branch_vld = 1'b1;
			branch_trgt = alu_branch_target[11:2];
			branch_taken = alu_branch_taken;
		end
	end

	always_ff @( posedge clk_i ) begin
		if (rst_i) begin
			halted_o <= 1'b0;
		end
		else if (states_current == S_WRITEBACK && instr_type == EBREAK) begin
			halted_o <= 1'b1;
		end
	end

	always_comb begin
		dsram_en_o = 1'b0;
		dsram_write_en_o = 1'b0;
		dsram_addr_o     = '0;
		dsram_wdata_o    = '0;

		if (states_current == S_MEM_WAIT) begin
			dsram_en_o = 1'b1;
			dsram_addr_o = alu_mem_addr[11:2];
			if (instr_type == STORE) begin
				dsram_write_en_o = 1'b1;
				dsram_wdata_o = rs2_data;
			end
		end
	end

	always_comb begin
		rd_write_en = 1'b0;
		rd_write_data = 32'd0;
		if (states_current == S_WRITEBACK) begin
			case (instr_type)
				ADDI, ADD, SUB, SLL, SRL: begin
					rd_write_en = 1'b1;
					rd_write_data = alu_result;
				end
				LOAD: begin
					rd_write_en = 1'b1;
					rd_write_data = dsram_rdata_i;
				end
				default: ;
			endcase
		end
	end

endmodule