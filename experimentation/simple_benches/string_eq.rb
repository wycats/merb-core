require "rubygems"
require "rbench"

HELLO = "Hello"
HELLO_F = "Hello".freeze
HELLO_S = "Hello".to_sym
HELLO2 = "Hello"
HELLO2_S = "Hello".to_sym
HELLO2_F = "Hello".freeze
GOODBYE = "Goodbye"
GOODBYE_F = "Goodbye".freeze
GOODBYE_S = "Goodbye".to_sym

RBench.run(1_000_000) do
  column :eql
  column :eql_eql
  
  group "Same" do
    report "Regular" do
      eql {HELLO.eql? HELLO2}
      eql_eql {HELLO == HELLO2}
    end
    
    report "Frozen" do
      eql {HELLO_F.eql? HELLO2_F}
      eql_eql {HELLO_F == HELLO2_F}
    end
    
    report "Symbol" do
      eql {HELLO_S.eql? HELLO2_S}
      eql_eql {HELLO_S == HELLO2_S}      
    end
  end
  
  group "Different" do
    report "Regular" do
      eql {HELLO.eql? GOODBYE}
      eql_eql {HELLO == GOODBYE}   
    end
    report "Frozen" do
      eql {HELLO_F.eql? GOODBYE_F}
      eql_eql {HELLO_F == GOODBYE_F}    
    end    
    report "Symbol" do
      eql {HELLO_S.eql? GOODBYE_S}
      eql_eql {HELLO_S == GOODBYE_S}      
    end    
  end
end

#                       EQL | EQL_EQL |
# --Same-------------------------------
# Regular             0.633 |   0.632 |
# Frozen              0.625 |   0.631 |
# Symbol              0.602 |   0.597 |
# --Different--------------------------
# Regular             0.616 |   0.612 |
# Frozen              0.623 |   0.602 |
# Symbol              0.600 |   0.608 |
