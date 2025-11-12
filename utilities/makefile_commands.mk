# OS-specific commands
ifeq ($(OS),Windows_NT)
RemoveDir = if exist $(subst /,\\,$(1)) rmdir /S /Q $(subst /,\\,$(1))
MakeDir := mkdir
MoveDir := move
CopyDir = cmd /C "xcopy $(subst /,\\,$(1)) $(subst /,\\,$(2)) /E /I /Y >nul"
CopyFile = cmd /C "copy $(subst /,\\,$(1)) $(subst /,\\,$(2)) >nul"
ChangeDir := cd
else
RemoveDir = rm -rf $(1)
MakeDir := mkdir -p
MoveDir := mv
CopyDir = cp -r "$(1)" "$(2)"
CopyFile = cp "$(1)" "$(2)"
ChangeDir := cd
endif

# Define helper functions
define safe_rmdir
	@$(call RemoveDir,$(1))
endef