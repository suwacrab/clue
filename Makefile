# compiler ------------------------------------------------------------------@/
CXX	:= clang++
CC	:= clang

CFLAGS := -Wall -Wshadow -Werror -Iinclude --std=gnu23
CFLAGS += --write-user-dependencies -MP

LDFLAGS := 
LDFLAGS += $(shell pkgconf --libs lua)

# output --------------------------------------------------------------------@/
OBJ_DIR := build
SRC_DIR := source
OUTPUT  := bin/program.exe

SRCS_C   := $(shell find $(SRC_DIR) -name *.c)
SRCS_CPP := $(shell find $(SRC_DIR) -name *.cpp)

OBJS := $(subst $(SRC_DIR),$(OBJ_DIR),$(SRCS_C:.c=.o))
OBJS += $(subst $(SRC_DIR),$(OBJ_DIR),$(SRCS_CPP:.cpp=.o))
DEPS := $(OBJS:.o=.d)

-include $(DEPS)

# building ------------------------------------------------------------------@/
all: $(OUTPUT)

$(OUTPUT): $(OBJS)
	$(CXX) $^ $(LDFLAGS) -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	$(CXX) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(OBJS) $(DEPS) $(OUTPUT)

rebuild: clean .WAIT all

