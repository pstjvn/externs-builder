#This makefile assumes you have your tools in a parent directory as follow
# __someparentfoler__
# 	compiler/
# 		compiler.jar
# 	library/
# 		svn checkout of the latest closure library
# 	stylesheets/
# 		cs.jar
# 	templates/
# 		SoyToJsCompiler.jar
# 		soyutils.js
# 		soyutils_usegoog.js
# 	apps/
# 		@yourproject
# 	jsdoc/
# 		plugins/removegoog.js
#
#
# 	Project structure:
# 	/ - list of html files to load. $(NS).html format is preferred.
# 	assets/ - all images and static assets (fonts etc).
# 	build/ - the build files will be put in there.
# 	gss/ - gss source files in this directory will be always included.
# 		common/ - gss source files in this directory will also be always included, but are considered imported from elsewhere (i.e. not project specific)
# 		$(NS)/ - gss sources that are specific to the name space that is being build.
# 	js/ - tree of JavaScript files that will be available to the project (project specific). Could include a sub-module with another project if needed.
# 		templates/ - flat list of soy files to compile.
# 	tpl/ - list of locales that have been built
# 		$(LOCALE)/ - locale specific build of the templates.



# This should match most projects.
APPDIR=$(shell basename `pwd`)

# The default name space to build. Could be modified on the command line.
NS=app

# The directory name to use as a build target directory. All compiled
# JavaScript, CSS and dependency files will be stored there. The directory is
# considered dirty and is ignored by Git.
BUILDDIR=build

# The directory to put translation files in.
I18NDIR=i18n

# Option to localize / internationalize the project. Set to desired locale when
# compiling. The locale is propagated to the closure compiler.
LOCALE=en

# Where the compiled templates should be kept
# Basically we want them out of the build dir as they are not a build result of its own
TEMPLATE_TMP_DIR=tpl/

# The sources of the templates.
TEMPLATES_SOURCE_DIR=templates/

# common library paths
PSTJ=../pstj/
SMJS=../smjs/
GCW=../gcw/

# if the build should use goog debug, bu default we want to use debug
DEBUG=true

########################################
# Service variables. Please change those only if you know what you are doing!!!
#######################################
LIBRARY_PATH=../../library/
DEPSWRITER_BIN=$(LIBRARY_PATH)closure/bin/build/depswriter.py
TEMPLATES_PATH=../../templates/
APPS_PATH=apps/

# The jar execs
COMPILER_JAR=../../compiler/compiler.jar
SOY_COMPILER_JAR=../../templates/SoyToJsSrcCompiler.jar
MESSAGE_EXTRACTOR_JAR=../../templates/SoyMsgExtractor.jar
STYLES_COMPILER_JAR=../../stylesheets/closure-stylesheets.jar

EXTERNS_PATH=../../externs/
CLOSURE_BUILDER=$(LIBRARY_PATH)closure/bin/build/closurebuilder.py


# Inlude for all javascript sources we know of. Note that the compiler will
# reorder them and will only use the files that are actually required. Make sure
# to exclude any *_test.js* files and include only javascript files. By default
# the files that do not use require/provide will be excluded from the compilation.
define JSSOURCES
--js="js/**.js" \
--js="tpl/$(LOCALE)/**.js" \
--js="../pstj/animation/**.js" \
--js="../pstj/color/**.js" \
--js="../pstj/config/**.js" \
--js="../pstj/control/**.js" \
--js="../pstj/date/**.js" \
--js="../pstj/debug/**.js" \
--js="../pstj/ds/**.js" \
--js="../pstj/error/**.js" \
--js="../pstj/fx/**.js" \
--js="../pstj/graphics/**.js" \
--js="../pstj/material/**.js" \
--js="../pstj/math/**.js" \
--js="../pstj/mvc/**.js" \
--js="../pstj/ng/**.js" \
--js="../pstj/object/**.js" \
--js="../pstj/resource/**.js" \
--js="../pstj/storage/**.js" \
--js="../pstj/style/**.js" \
--js="../pstj/themes/**.js" \
--js="../pstj/ui/**.js" \
--js="../../templates/soyutils_usegoog.js" \
--js="../../library/closure/goog/**.js" \
--js="!**_test.js" \
--js="../../library/third_party/closure/goog/mochikit/async/deferred.js" \
--js="../../library/third_party/closure/goog/mochikit/async/deferredlist.js"
endef

# Following definitions are used only by the closure builder script.
# We use it instead of the closure compiler to produce filelist for the
# compiler to build from as the former works much faster.
define JSROOTS
--root=js/ \
--root=$(TEMPLATE_TMP_DIR)/$(LOCALE)/ \
--root=$(PSTJ) \
--root=$(SMJS) \
--root=$(TEMPLATES_PATH) \
--root=$(LIBRARY_PATH)
endef

define JSDEPS
-f --js=build/deps.js \
-f --js=$(TEMPLATES_PATH)/deps.js \
-f --js=$(PSTJ)/deps.js \
-f --js=$(SMJS)/deps.js \
-f --js=$(GCW)/deps.js
endef

# Define all templates possible to be used.
TERMPLATES_SOURCES = templates/*.soy ../pstj/templates/*.soy ../smjs/templates/*.soy

# Default compiler call. Tweak this in the compilation steps.
define COMPILER
java -jar $(COMPILER_JAR) \
--charset=UTF-8 \
--closure_entry_point=$(NS) \
--define='goog.LOCALE="$(LOCALE)"' \
--define='goog.DEBUG=$(DEBUG)' \
--flagfile=options/compile.ini \
--manage_closure_dependencies \
--process_closure_primitives \
--use_types_for_optimization \
--warning_level=VERBOSE
endef

# Same as the compiler but exclude all files that are not to be used and
# force it to read all files.
define FILELISTER
$(COMPILER) \
--only_closure_dependencies \
$(JSSOURCES)
endef

define GITIGNOREFILE
build/ $(TEMPLATE_TMP_DIR) help/ *sublime-*
endef

# The file list for actual compilation. Note that because the compiler now
# manages its dependencies alone if we want a clean compile we need to either
# provide it with the files to include or use --only_closure_deps, but the later
# excudes the css map file from the compile which results in a mismatch
# between the css names in the templates and the css names in the js. Thus we
# first generate a list of files to include (with only closire deps) and then we
# use that file list plus the css map
FL=`cat $(BUILDDIR)/filelist.txt | tr '\n' ' '`



################################################################################
###   TARGETED RULES
################################################################################

# Default build to execute on 'make'. Includes the css the templates and the
# deps file
# all: $(BUILDDIR)/$(NS).css $(TEMPLATE_TMP_DIR)/$(LOCALE)/*.soy.js $(BUILDDIR)/deps.js


################################################################################
# THE DEFAULT BUILD TARGET

# For basic run we require the css map, the css itself (intermediate requirement
# from the css map) and the depencency file. The templates also require to be
# built but those are also transeient requirement by the deps.
#all: $(BUILDDIR)/$(NS)-cssmap.js $(BUILDDIR)/deps.js .pstjdeps .smjsdeps
all: .pstjdeps .smjsdeps
	@echo 'All done'

################################################################################
# CHECK JS VALIDITY

gitignore:
	echo '$(GITIGNOREFILE)' | tr ' ' '\n' > .gitignore

# same as above but also build deps in local project
commit: $(BUILDDIR)/deps.js check

# Linting all source files in the current project. Note that we monitor for
# changes in those file and linter is always run when a single file changes.
LINTFLAGS?=-r
lintdeps = js/**.js
.linted: $(lintdeps)
	@echo -n 'Linting...'
	@gjslint \
	--jslint_error=all \
	--strict \
	--disable 0251 \
	--max_line_length 80 \
	-e "vendor,tpl" \
	$(LINTFLAGS) \
	js/
	@touch .linted

.pstjlint: ../pstj/*/**.js
	@gjslint \
	--jslint_error=all \
	--strict \
	--disable 0251 \
	--max_line_length 80 \
	-e "vendor,tpl,nodejs" \
	$(LINTFLAGS) \
	../pstj/
	touch .pstjlint

.smjslint: ../smjs/*/**.js
	@gjslint \
	--jslint_error=all \
	--strict \
	--disable 0251 \
	--max_line_length 80 \
	-e "vendor,tpl" \
	$(LINTFLAGS) \
	../smjs/
	touch .smjslint

# Build the template files for the project only.
# Because we use translation file by default we also depend on the translation and
# the translation file itself depends on changed of all soy files so basically
# we stll depend on all soy files being considered.
tplbuilddeps = $(I18NDIR)/translations_$(LOCALE).xlf
$(TEMPLATE_TMP_DIR)/$(LOCALE)/$(NS).soy.js: $(tplbuilddeps)
	@echo -n 'Building  project templates...'
	@java -jar $(SOY_COMPILER_JAR) \
	--locales $(LOCALE) \
	--messageFilePathFormat "$(I18NDIR)/translations_$(LOCALE).xlf" \
	--shouldProvideRequireSoyNamespaces \
	--shouldGenerateJsdoc \
	--codeStyle concat \
	--cssHandlingScheme GOOG \
	--outputPathFormat '$(TEMPLATE_TMP_DIR)/$(LOCALE)/{INPUT_FILE_NAME_NO_EXT}.soy.js' \
	$(TERMPLATES_SOURCES)

# Builds the dependency file. Note that the file depends on the templates built
# from the soy files in the project only. See above rule for details.
depsdeps = js/* $(TEMPLATE_TMP_DIR)/$(LOCALE)/$(NS).soy.js
$(BUILDDIR)/deps.js: $(depsdeps)
	@echo -n 'Constructing project dependencies..'
	@python $(DEPSWRITER_BIN) \
	--root_with_prefix="js ../../../$(APPS_PATH)$(APPDIR)/js" \
	--root_with_prefix="$(TEMPLATE_TMP_DIR)/$(LOCALE) ../../../$(APPS_PATH)/$(APPDIR)/$(TEMPLATE_TMP_DIR)/$(LOCALE)/" \
	--output_file="$(BUILDDIR)/deps.js"


../pstj/templates/icons.soy: ../pstj/templates/icons.xml
	@echo -n 'Code auto-generation'
	@cd ../pstj && make codegen

# Extracts the translation messages from the templates in a file.
# Translated file should be used to compile to a different locale.
# NOTE: by default all messages from all templates are extracted. Note that
# not all messages will be used because not all templates are actually being
# included in the build.
$(I18NDIR)/translations_$(LOCALE).xlf: $(TERMPLATES_SOURCES)
	@echo -n 'Extracting translatable messages...'
	@java -jar $(MESSAGE_EXTRACTOR_JAR) \
	--outputFile "$(I18NDIR)/translations_$(LOCALE).xlf" \
	--targetLocaleString $(LOCALE) \
	$(TERMPLATES_SOURCES)

# Compile the less definitions into a single file. Note that we monitor all
# possible files we might use even if we not really use them (as those might not
# be imported in the app less file.
# List of static files that are dependencies.
lesssourcess = less/$(NS).less less/$(NS)/*.less ../smjs/less/*.less ../pstj/less/*/*.less
less/$(NS).css: $(lesssourcess)
	@echo -n 'Building CSS from LESS...'
	lessc --no-ie-compat less/$(NS).less > less/$(NS).css

# Create CSS file for name space and put name mapping in the build dir.
# This build depends on the less files
$(BUILDDIR)/$(NS).css: less/$(NS).css
	@echo -n 'Building compact CSS...'
	@java -jar $(STYLES_COMPILER_JAR) \
	`cat options/css.ini | tr '\n' ' '` \
	--output-file $(BUILDDIR)/$(NS).css \
	--output-renaming-map $(BUILDDIR)/$(NS)-cssmap.js \
	less/$(NS).css

# Dummy rile for the css map should someone require it (ALL)
$(BUILDDIR)/$(NS)-cssmap.js: $(BUILDDIR)/$(NS).css


### FROM HERE BELLOW THE COMPILER IS CALLED

# Creates a css file that is built with the closure renaming map inside
# of it so the compiler can find the class names.
$(BUILDDIR)/$(NS).build.css: less/$(NS).css
	@echo -n 'Advance compiling CSS...'
	@java -jar $(STYLES_COMPILER_JAR) \
	`cat options/cssbuild.ini | tr '\n' ' '` \
	--output-file $(BUILDDIR)/$(NS).build.css \
	--output-renaming-map $(BUILDDIR)/cssmap-build.js \
  less/$(NS).css

# Dummy rule to allow the requirement of the css map from the compiler
$(BUILDDIR)/cssmap-build.js: $(BUILDDIR)/$(NS).build.css

# We depend on all possible js files as well as the css map.
# local project files
# local templates
# pstj lib files
# pstj templates
# simple css names map
simpledeps = $(BUILDDIR)/$(NS)-cssmap.js js/** ../pstj/*/**.js $(BUILDDIR)/filelist.txt
$(BUILDDIR)/$(NS).simple.js: $(simpledeps)
	@echo 'Performing simple compilation...'
	$(COMPILER) \
	--compilation_level=SIMPLE \
	--js="$(BUILDDIR)/$(NS)-cssmap.js"  \
	--js_output_file=$(BUILDDIR)/$(NS).simple.js \
	$(FL)
	@wc -c $(BUILDDIR)/$(NS).simple.js

# Dummy rule to perform the simple compilation
simple: $(BUILDDIR)/$(NS).simple.js
	@echo 'Done'

# Compile javascript with advanced optimizations enabled. Use for production only
# with DEBUG set to false.
# Dependencies
# css names map - compiled
# local / project js files
# local templates
# pstj lib js files
# pstj templates
advanceddeps=$(BUILDDIR)/cssmap-build.js js/** $(TEMPLATE_TMP_DIR)/$(LOCALE)/*.js ../pstj/*/**.js
$(BUILDDIR)/$(NS).advanced.js: $(advanceddeps) $(BUILDDIR)/filelist.txt
	@echo 'Performing advanced compilation...'
	$(COMPILER) \
	--compilation_level=ADVANCED \
	--js="$(BUILDDIR)/cssmap-build.js"  \
	--js_output_file=$(BUILDDIR)/$(NS).advanced.js \
	$(FL)
	@wc -c $(BUILDDIR)/$(NS).advanced.js

# Dummy call for compiling everything in advanced mode.
# requirements:
# same as the advanced compiled js,
# the advance compiled css file
advanced: $(BUILDDIR)/$(NS).build.css $(BUILDDIR)/$(NS).advanced.js options/*
	@echo 'Done'


$(BUILDDIR)/$(NS).debug.js: $(BUILDDIR)/$(NS)-cssmap.js $(advanced) $(BUILDDIR)/filelist.txt
	@echo 'Building debug JS...'
	$(COMPILER) \
	--compilation_level=ADVANCED \
	--debug \
	--formatting=PRETTY_PRINT \
	--js_output_file=$(BUILDDIR)/$(NS).debug.js \
	$(FL)

debug: $(BUILDDIR)/$(NS).debug.js
	@echo 'Done'

# Creates a file list that can be used to create the module list when compiling
# the project with module support
# Set target specific variables (output file name and compilation level)
$(BUILDDIR)/filelist.txt: js/** tpl/$(LOCALE)/*.js ../pstj/*/**.js
	@echo -n 'Compiling list of files for modules...'
	@$(CLOSURE_BUILDER) -n $(NS) \
	$(JSROOTS) $(JSDEPS) \
	-o list \
	--output_file=$(BUILDDIR)/filelist.txt
	@echo 'Done building filelist'


# $(FILELISTER) \
# --only_closure_dependencies \
# --output_manifest=$(BUILDDIR)/filelist.txt
# @echo 'Done'

compact: advanced
	@echo -n 'Inlining resources in main html file...'
	node ../../node/inline.js $(NS)-deploy.html
	@echo 'Done'

# For the heck no need to build the file list, just use only closure and it will spill out
# the errors.
check: js/** ../pstj/*/**.js ../smjs/*/**.js $(BUILDDIR)/cssmap-build.js
	$(COMPILER) \
	--compilation_level=ADVANCED \
	--js="$(BUILDDIR)/cssmap-build.js"  \
	--js_output_file=/tmp/check.js \
	--only_closure_dependencies \
	$(JSSOURCES)
	@echo 'Done'

checkspecific:
	$(COMPILER) \
	--compilation_level=ADVANCED \
	--js="$(BUILDDIR)/cssmap-build.js"  \
	--js_output_file=/tmp/check.js \
	--only_closure_dependencies \
	$(JSSOURCES)


checkall: .linted .pstjlint .smjslint check

libdeps: .pstjdeps .smjsdeps
	@echo 'All library deps up to date'

.pstjdeps: ../pstj/*/**.js ../pstj/*/*/*.js
	cd ../pstj/ && make libdeps
	touch .pstjdeps

.smjsdeps: ../smjs/*/**.js
	cd ../smjs/ && make libdeps
	touch .smjsdeps
