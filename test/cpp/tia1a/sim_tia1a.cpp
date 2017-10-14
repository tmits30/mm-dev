//------------------------------------------------------------------------------
// Simlation for Television Interface Adaptor (Model 1A)
//------------------------------------------------------------------------------

#include <fstream>
#include <iomanip>
#include <iostream>
#include <fstream>
#include <map>
#include <memory>

#include <yaml-cpp/yaml.h>

#include "verilated_vcd_c.h"
#include "Vtia1a.h"


template <typename T>
decltype(auto) HexString(const T& x, const int d = 2)
{
    std::stringstream ret;
    ret << "0x" << std::hex << std::setw(d) << std::setfill('0')
        << static_cast<int>(x);
    return ret.str();
}


class TestBench
{
#define TIA1A_TOP(ptr, element) \
    (ptr)->tia1a__DOT__##element

public:

    //--------------------------------------------------------------------------
    // Helper class
    //--------------------------------------------------------------------------

    struct ModuleValues
    {
        using value_type = int;

        ModuleValues(
            const std::vector<std::string>& keys, const YAML::Node& nodes)
        {
            // Initialize to zero
            for (const auto& key : keys) {
                values_.emplace(key, std::make_tuple(0, false));
            }
            // Set values from yaml
            for (const auto& node : nodes) {
                const auto& key = node.first.as<std::string>();
                const auto& value = node.second.as<value_type>();
                values_[key] = std::make_tuple(value, true);
            }
        }

        value_type operator()(const std::string& key) const
        {
            return std::get<0>(values_.at(key));
        }

        bool IsSet(const std::string& key) const
        {
            return std::get<1>(values_.at(key));
        }

        std::map<std::string, std::tuple<value_type, bool>> values_;
    };

    struct Inputs : public ModuleValues
    {
        Inputs(const YAML::Node& nodes) :
            ModuleValues(GetKeys(), nodes)
        {}

        const std::vector<std::string> GetKeys() const
        {
            return {
                "DEL", "R_W", "CS", "A", "I", "D_IN"
            };
        }
    };

    struct Outputs : public ModuleValues
    {
        Outputs(const YAML::Node& nodes) :
            ModuleValues(GetKeys(), nodes)
        {}

        const std::vector<std::string> GetKeys() const
        {
            return {
                "HSYNC", "HBLANK", "VSYNC", "VBLANK",
                "RDY", "LUM", "COL", "AUD", "D_OUT"
            };
        }
    };

    struct Registers : public ModuleValues
    {
        Registers(const YAML::Node& nodes) :
            ModuleValues(GetKeys(), nodes)
        {}

        const std::vector<std::string> GetKeys() const
        {
            return {
                "VSYNC", "VBLANK", "NUSIZ0", "NUSIZ1",
                "COLUP0", "COLUP1", "COLUPF", "COLUBK", "CTRLPF",
                "REFP0", "REFP1", "PF0", "PF1", "PF2",
                "GRP0", "GRP1", "GRP0D", "GRP1D",
                "ENAM0", "ENAM1", "ENABL", "ENABLD",
                "HMP0", "HMP1", "HMM0", "HMM1", "HMBL",
                "POSP0", "POSP1", "POSM0", "POSM1", "POSBL",
                "VDELP0", "VDELP1", "VDELBL",
                "RESMP0", "RESMP1", "CXCLR", "CXR",
            };
        }
    };

    const int PERIOD = 1;

    TestBench(const std::string vcd_file = "") :
        top_(std::make_unique<Vtia1a>("top")),
        vcd_(std::make_unique<VerilatedVcdC>()),
        vcd_file_(vcd_file),
        vcd_time_(0)
    {
        if (vcd_file_ != "") {
            Verilated::traceEverOn(true);
            top_->trace(vcd_.get(), 99);
            vcd_->open(vcd_file_.c_str());
        }
    }

    ~TestBench()
    {
        if (vcd_file_ != "") {
            vcd_->close();
        }
        top_->final();
    }

    void Reset(const Registers& regs)
    {
        // Reset
        RES_N(0); CCLK(0);
        const auto end_time = (PERIOD * 2) * 1;
        for (auto time = decltype(end_time)(0); time < end_time; ++time) {
            if ((time % PERIOD) == 0) {
                CCLK(!CCLK());
            }
            top_->eval();
        }

        // Set register
        RES_N(1); CCLK(1); MCLK(1);
        SetRegisters(regs);
    }

    void Run(const int cycles, const std::map<int, Inputs>& inputs,
             const std::string& screen_name = "")
    {
        constexpr int CCLK_PER_MCLK = 3;

        std::ofstream screen;
        if (screen_name.length() > 0) {
            screen.open(screen_name, std::ios::out | std::ios::binary);
        }

        int clock = 0;
        const auto end_time = PERIOD * (2 * (cycles + 1) + 1);
        for (auto time = decltype(end_time)(0); time < end_time; ++time) {
            // Dump signals
            if (vcd_file_ != "") {
                vcd_->dump(vcd_time_);
            }

            // Execute
            if (((time + 1) % PERIOD) == 0) {
                CCLK(!CCLK());
                clock += CCLK();
            }
            if (((time + 1) % (PERIOD * CCLK_PER_MCLK)) == 0) {
                MCLK(!MCLK());
            }
            top_->eval();

            // Input data to module
            const auto it = inputs.find(clock);
            if (it != inputs.end()) {
                const auto inputs = it->second;
                SetInputs(inputs);
            }
            top_->eval();

            // Dump pixel to file
            if ((HCOUNT_REG() >= 68) && CCLK()) {
                uint8_t colu = (COL() << 4) | (LUM() << 1);
                screen.write(reinterpret_cast<char *>(&colu), sizeof(char));
            }

            // Count up timer for VCD
            vcd_time_ += 1;
        }

        if (screen_name.length() > 0) {
            screen.close();
        }
    }

    bool Verify(const Outputs& outputs, const Registers& regs)
    {
        bool ret = true;

        // Verify register
        auto verify_func = [&ret](
            const std::string name,
            const ModuleValues& values,
            const int actual) {
            if (values.IsSet(name)) {
                const auto expected = values(name);
                if (expected != actual) {
                    ret = false;
                    std::cout << "error: " << name
                              << " (expected " << HexString(expected)
                              << ", actual " << HexString(actual) << ")"
                              << std::endl;
                }
            }
        };

        // For outputs
        verify_func("HSYNC", outputs, HSYNC());
        verify_func("HBLANK", outputs, HBLANK());
        verify_func("VSYNC", outputs, VSYNC());
        verify_func("VBLANK", outputs, VBLANK());
        verify_func("RDY", outputs, RDY());
        verify_func("LUM", outputs, LUM());
        verify_func("COL", outputs, COL());
        verify_func("AUD", outputs, AUD());
        verify_func("D_OUT", outputs, D_OUT());

        //For registers
        verify_func("VSYNC", regs, VSYNC_REG());
        verify_func("VBLANK", regs, VBLANK_REG());
        verify_func("NUSIZ0", regs, NUSIZ0_REG());
        verify_func("NUSIZ1", regs, NUSIZ1_REG());
        verify_func("COLUP0", regs, COLUP0_REG());
        verify_func("COLUP1", regs, COLUP1_REG());
        verify_func("COLUPF", regs, COLUPF_REG());
        verify_func("COLUBK", regs, COLUBK_REG());
        verify_func("CTRLPF", regs, CTRLPF_REG());
        verify_func("REFP0", regs, REFP0_REG());
        verify_func("REFP1", regs, REFP1_REG());
        verify_func("PF0", regs, PF0_REG());
        verify_func("PF1", regs, PF1_REG());
        verify_func("PF2", regs, PF2_REG());
        verify_func("GRP0" , regs, GRP0_REG());
        verify_func("GRP1" , regs, GRP1_REG());
        verify_func("GRP0D", regs, GRP0D_REG());
        verify_func("GRP1D", regs, GRP1D_REG());
        verify_func("ENAM0", regs, ENAM0_REG());
        verify_func("ENAM1", regs, ENAM1_REG());
        verify_func("ENABL", regs, ENABL_REG());
        verify_func("ENABLD", regs, ENABLD_REG());
        verify_func("HMP0", regs, HMP0_REG());
        verify_func("HMP1", regs, HMP1_REG());
        verify_func("HMM0", regs, HMM0_REG());
        verify_func("HMM1", regs, HMM1_REG());
        verify_func("HMBL", regs, HMBL_REG());
        verify_func("POSP0", regs, POSP0_REG());
        verify_func("POSP1", regs, POSP1_REG());
        verify_func("POSM0", regs, POSM0_REG());
        verify_func("POSM1", regs, POSM1_REG());
        verify_func("POSBL", regs, POSBL_REG());
        verify_func("VDELP0", regs, VDELP0_REG());
        verify_func("VDELP1", regs, VDELP1_REG());
        verify_func("VDELBL", regs, VDELBL_REG());
        verify_func("RESMP0", regs, RESMP0_REG());
        verify_func("RESMP1", regs, RESMP1_REG());
        verify_func("CXCLR", regs, CXCLR_REG());
        verify_func("CXR", regs, CXR_REG());

        return ret;
    }

    void SetInputs(const Inputs& values)
    {
        DEL(values("DEL"));
        R_W(values("R_W"));
        CS(values("CS"));
        A(values("A"));
        I(values("I"));
        D_IN(values("D_IN"));
    }

    void SetOutputs(const Outputs& values)
    {
        HSYNC(values("HSYNC"));
        HBLANK(values("HBLANK"));
        VSYNC(values("VSYNC"));
        VBLANK(values("VBLANK"));
        RDY(values("RDY"));
        LUM(values("LUM"));
        COL(values("COL"));
        AUD(values("AUD"));
        D_OUT(values("D_OUT"));
    }

    void SetRegisters(const Registers& values)
    {
        VSYNC_REG(values("VSYNC"));
        VBLANK_REG(values("VBLANK"));
        NUSIZ0_REG(values("NUSIZ0"));
        NUSIZ1_REG(values("NUSIZ1"));
        COLUP0_REG(values("COLUP0"));
        COLUP1_REG(values("COLUP1"));
        COLUPF_REG(values("COLUPF"));
        COLUBK_REG(values("COLUBK"));
        CTRLPF_REG(values("CTRLPF"));
        REFP0_REG(values("REFP0"));
        REFP1_REG(values("REFP1"));
        PF0_REG(values("PF0"));
        PF1_REG(values("PF1"));
        PF2_REG(values("PF2"));
        GRP0_REG(values("GRP0"));
        GRP1_REG(values("GRP1"));
        GRP0D_REG(values("GRP0D"));
        GRP1D_REG(values("GRP1D"));
        ENAM0_REG(values("ENAM0"));
        ENAM1_REG(values("ENAM1"));
        ENABL_REG(values("ENABL"));
        ENABLD_REG(values("ENABLD"));
        HMP0_REG(values("HMP0"));
        HMP1_REG(values("HMP1"));
        HMM0_REG(values("HMM0"));
        HMM1_REG(values("HMM1"));
        HMBL_REG(values("HMBL"));
        POSP0_REG(values("POSP0"));
        POSP1_REG(values("POSP1"));
        POSM0_REG(values("POSM0"));
        POSM1_REG(values("POSM1"));
        POSBL_REG(values("POSBL"));
        VDELP0_REG(values("VDELP0"));
        VDELP1_REG(values("VDELP1"));
        VDELBL_REG(values("VDELBL"));
        RESMP0_REG(values("RESMP0"));
        RESMP1_REG(values("RESMP1"));
        CXCLR_REG(values("CXCLR"));
        CXR_REG(values("CXR"));
    }

    // Getter and Setter
#define DECL_ACCESSOR(type, func, var) \
    type func() { return var; } \
    const type func() const { return var; } \
    void func(const type wd) { var = wd; }

    // Accessor for inputs
    DECL_ACCESSOR(uint8_t, MCLK, top_->MCLK);     // 1-bit
    DECL_ACCESSOR(uint8_t, CCLK, top_->CCLK);     // 1-bit
    DECL_ACCESSOR(uint8_t, RES_N, top_->RES_N);   // 1-bit
    DECL_ACCESSOR(uint8_t, DEL, top_->DEL);       // 1-bit
    DECL_ACCESSOR(uint8_t, R_W, top_->R_W);       // 1-bit
    DECL_ACCESSOR(uint8_t, CS, top_->CS);         // 4-bit
    DECL_ACCESSOR(uint8_t, A, top_->A);           // 6-bit
    DECL_ACCESSOR(uint8_t, I, top_->I);           // 6-bit
    DECL_ACCESSOR(uint8_t, D_IN, top_->D_IN);     // 8-bit

    // Accessor for outputs
    DECL_ACCESSOR(uint8_t, RDY, top_->RDY);       // 1-bit
    DECL_ACCESSOR(uint8_t, HSYNC, top_->HSYNC);   // 1-bit
    DECL_ACCESSOR(uint8_t, HBLANK, top_->HBLANK); // 1-bit
    DECL_ACCESSOR(uint8_t, VSYNC, top_->VSYNC);   // 1-bit
    DECL_ACCESSOR(uint8_t, VBLANK, top_->VBLANK); // 1-bit
    DECL_ACCESSOR(uint8_t, LUM, top_->LUM);       // 3-bit
    DECL_ACCESSOR(uint8_t, COL, top_->COL);       // 4-bit
    DECL_ACCESSOR(uint8_t, AUD, top_->AUD);       // 2-bit
    DECL_ACCESSOR(uint8_t, D_OUT, top_->D_OUT);   // 8-bit

    // Accessor for internal registers
    DECL_ACCESSOR(uint8_t, VSYNC_REG, TIA1A_TOP(top_, vsync));     // 1-bit
    DECL_ACCESSOR(uint8_t, VBLANK_REG, TIA1A_TOP(top_, vblank));   // 8-bit
    DECL_ACCESSOR(uint8_t, NUSIZ0_REG, TIA1A_TOP(top_, nusiz0));   // 8-bit
    DECL_ACCESSOR(uint8_t, NUSIZ1_REG, TIA1A_TOP(top_, nusiz1));   // 8-bit
    DECL_ACCESSOR(uint8_t, COLUP0_REG, TIA1A_TOP(top_, colup0));   // 8-bit
    DECL_ACCESSOR(uint8_t, COLUP1_REG, TIA1A_TOP(top_, colup1));   // 8-bit
    DECL_ACCESSOR(uint8_t, COLUPF_REG, TIA1A_TOP(top_, colupf));   // 8-bit
    DECL_ACCESSOR(uint8_t, COLUBK_REG, TIA1A_TOP(top_, colubk));   // 8-bit
    DECL_ACCESSOR(uint8_t, CTRLPF_REG, TIA1A_TOP(top_, ctrlpf));   // 8-bit
    DECL_ACCESSOR(uint8_t, REFP0_REG, TIA1A_TOP(top_, refp0));     // 1-bit
    DECL_ACCESSOR(uint8_t, REFP1_REG, TIA1A_TOP(top_, refp1));     // 1-bit
    DECL_ACCESSOR(uint8_t, PF0_REG, TIA1A_TOP(top_, pf0));         // 8-bit
    DECL_ACCESSOR(uint8_t, PF1_REG, TIA1A_TOP(top_, pf1));         // 8-bit
    DECL_ACCESSOR(uint8_t, PF2_REG, TIA1A_TOP(top_, pf2));         // 8-bit
    DECL_ACCESSOR(uint8_t, GRP0_REG, TIA1A_TOP(top_, grp0));       // 8-bit
    DECL_ACCESSOR(uint8_t, GRP1_REG, TIA1A_TOP(top_, grp1));       // 8-bit
    DECL_ACCESSOR(uint8_t, GRP0D_REG, TIA1A_TOP(top_, grp0d));     // 8-bit
    DECL_ACCESSOR(uint8_t, GRP1D_REG, TIA1A_TOP(top_, grp1d));     // 8-bit
    DECL_ACCESSOR(uint8_t, ENAM0_REG, TIA1A_TOP(top_, enam0));     // 1-bit
    DECL_ACCESSOR(uint8_t, ENAM1_REG, TIA1A_TOP(top_, enam1));     // 1-bit
    DECL_ACCESSOR(uint8_t, ENABL_REG, TIA1A_TOP(top_, enabl));     // 1-bit
    DECL_ACCESSOR(uint8_t, ENABLD_REG, TIA1A_TOP(top_, enabld));   // 1-bit
    DECL_ACCESSOR(uint8_t, HMP0_REG, TIA1A_TOP(top_, hmp0));       // 8-bit
    DECL_ACCESSOR(uint8_t, HMP1_REG, TIA1A_TOP(top_, hmp1));       // 8-bit
    DECL_ACCESSOR(uint8_t, HMM0_REG, TIA1A_TOP(top_, hmm0));       // 8-bit
    DECL_ACCESSOR(uint8_t, HMM1_REG, TIA1A_TOP(top_, hmm1));       // 8-bit
    DECL_ACCESSOR(uint8_t, HMBL_REG, TIA1A_TOP(top_, hmbl));       // 8-bit
    DECL_ACCESSOR(uint8_t, POSP0_REG, TIA1A_TOP(top_, posp0));     // 8-bit
    DECL_ACCESSOR(uint8_t, POSP1_REG, TIA1A_TOP(top_, posp1));     // 8-bit
    DECL_ACCESSOR(uint8_t, POSM0_REG, TIA1A_TOP(top_, posm0));     // 8-bit
    DECL_ACCESSOR(uint8_t, POSM1_REG, TIA1A_TOP(top_, posm1));     // 8-bit
    DECL_ACCESSOR(uint8_t, POSBL_REG, TIA1A_TOP(top_, posbl));     // 8-bit
    DECL_ACCESSOR(uint8_t, VDELP0_REG, TIA1A_TOP(top_, vdelp0));   // 1-bit
    DECL_ACCESSOR(uint8_t, VDELP1_REG, TIA1A_TOP(top_, vdelp1));   // 1-bit
    DECL_ACCESSOR(uint8_t, VDELBL_REG, TIA1A_TOP(top_, vdelbl));   // 1-bit
    DECL_ACCESSOR(uint8_t, RESMP0_REG, TIA1A_TOP(top_, resmp0));   // 1-bit
    DECL_ACCESSOR(uint8_t, RESMP1_REG, TIA1A_TOP(top_, resmp1));   // 1-bit
    DECL_ACCESSOR(uint8_t, CXCLR_REG, TIA1A_TOP(top_, cxclr));     // 1-bit
    DECL_ACCESSOR(uint16_t, CXR_REG, TIA1A_TOP(top_, cxr));        // 15-bit

    DECL_ACCESSOR(uint8_t, HCOUNT_REG, TIA1A_TOP(top_, hcount));   // 8-bit
    DECL_ACCESSOR(uint8_t, PIXEL_REG, TIA1A_TOP(top_, pixel));     // 8-bit

#undef DECL_ACCESSOR

private:

    std::unique_ptr<Vtia1a> top_;
    std::unique_ptr<VerilatedVcdC> vcd_;
    const std::string vcd_file_;
    int vcd_time_;

#undef TIA1A_TOP
};


int main(int argc, char **argv)
{
    // Intialize Verilated
    Verilated::commandArgs(argc, argv);

    // Create testbench
    auto tb = std::make_unique<TestBench>("sim_tia1a.vcd");

    // Read test config yaml file
    const auto test_patterns = YAML::LoadFile("sim_tia1a.yml");

    // Run tests from yaml file
    for (const auto& target : test_patterns) {
        const auto target_name = target["target"].as<std::string>();

        for (const auto& test : target["tests"]) {
            const auto comment = test["comment"].as<std::string>();

            // Execute a test pattern
            const auto& initial = test["initial"];
            tb->Reset(TestBench::Registers(initial["reg"]));

            // Run
            std::map<int, TestBench::Inputs> inputs;
            for (const auto& input : test["inputs"]) {
                inputs.emplace(
                    input["clock"].as<int>(),
                    TestBench::Inputs(input["in"]));
            }
            if (target_name == "Screen") {
                const auto screen_name = test["screen_name"].as<std::string>();
                tb->Run(test["cycle"].as<int>(), inputs, screen_name);
            } else {
                tb->Run(test["cycle"].as<int>(), inputs);
            }

            // Verify the test
            const auto& expected = test["expected"];
            const auto is_valid = tb->Verify(
                TestBench::Outputs(expected["out"]),
                TestBench::Registers(expected["reg"]));

            std::cout << (is_valid ? "Success" : "   Fail") << ": "
                      << target_name << ": "
                      << comment << std::endl;
        }
    }

    return 0;
}
