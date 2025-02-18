

  Sys.setenv(RETICULATE_PYTHON = RETICULATE_PYTHON)


  envname_c = reticulate::miniconda_path()

  py_install( "earthengine-api")
  py_install("geemap")###installing geemap python package


  rgee::ee_install_set_pyenv(
  py_path = paste0(RETICULATE_PYTHON),

  confirm=F,quiet=T)

rgee::ee_install()
rgee::ee_install_upgrade() #getting latest version of earth engine




reticulate::virtualenv_list()
