#
# Copyright © 2020 Banca D'Italia
#
# Licensed under the EUPL, Version 1.2 (the "License");
# You may not use this work except in compliance with the
# License.
# You may obtain a copy of the License at:
#
# https://joinup.ec.europa.eu/sites/default/files/custom-page/attachment/2020-03/EUPL-1.2%20EN.txt
#
# Unless required by applicable law or agreed to in
# writing, software distributed under the License is
# distributed on an "AS IS" basis,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied.
#
# See the License for the specific language governing
# permissions and limitations under the License.
#

library(RVTL)
library(bslib)

repoImpls <- c(
  `In-Memory repository` = 'it.bancaditalia.oss.vtl.impl.meta.InMemoryMetadataRepository',
  `Json URL repository` = 'it.bancaditalia.oss.vtl.impl.meta.json.JsonMetadataRepository',
  `SDMX REST Metadata repository` = 'it.bancaditalia.oss.vtl.impl.meta.sdmx.SDMXRepository',
  `SDMX REST & Json combined repository` = 'it.bancaditalia.oss.vtl.impl.meta.sdmx.SDMXJsonRepository'
)

environments <- list(
  `R Environment` = "it.bancaditalia.oss.vtl.impl.environment.REnvironment"
  , `CSV environment` = "it.bancaditalia.oss.vtl.impl.environment.CSVPathEnvironment"
  , `SDMX environment` = "it.bancaditalia.oss.vtl.impl.environment.SDMXEnvironment"
#  , `Spark environment` = "it.bancaditalia.oss.vtl.impl.environment.spark.SparkEnvironment"
)

currentEnvironments <- \() sapply(J("it.bancaditalia.oss.vtl.config.VTLGeneralProperties")$ENVIRONMENT_IMPLEMENTATION$getValues(), .jstrVal)

activeEnvs <- function(active) {
  items <- names(environments[xor(!active, environments %in% currentEnvironments())])
  if (length(items) > 0) items else NULL
}

vtlServer <- function(input, output, session) {

  configManager <- J("it.bancaditalia.oss.vtl.config.ConfigurationManagerFactory")
  vtlProperties <- J("it.bancaditalia.oss.vtl.config.VTLGeneralProperties")

  currentSession <- reactive(VTLSessionManager$getOrCreate(input$sessionID)) |> bindEvent(input$sessionID)
  evalNode <- reactive(currentSession()$getValues(input$selectDatasets)) |> bindEvent(input$selectDatasets)
  isCompiled <- reactiveVal(F)
  
  controlsGen <- function(javaclass) {
    renderUI({
      ctrls <- lapply(configManager$getSupportedProperties(J(javaclass)@jobj), function (prop) {
        val <- prop$getValue()
        if (val == 'null')
          val <- ''
        
        if (prop$isPassword()) {
          passwordInput(prop$getName(), prop$getDescription(), val)
        } else if (prop$isFolder()) {
          
        } else {
          textInput(prop$getName(), prop$getDescription(), val, placeholder = prop$getPlaceholder())
        }
      })

      do.call(tagList, ctrls)
    })
  }
  
  observers <- list()
  observerGen <- function(prop) {
    if (is.null(observers[[prop$getName()]])) {
      observers[[prop$getName()]] <- observe({
        val <- input[[prop$getName()]]
        if (prop$getValue() != val) {
          prop$setValue(val)
          output$eng_conf_output <- renderPrint({
            if (prop$isPassword()) {
              cat("Set property", prop$getDescription(), "to <masked value>\n")
            } else {
              cat("Set property", prop$getDescription(), "to", val, "\n")
            }
          })
          
          tryCatch({
            writer <- .jnew("java.io.StringWriter")
            configManager$newManager()$saveConfiguration(writer)
            string <- .jstrVal(writer$toString())
            propfile <- file.path(J("java.lang.System")$getProperty("user.home"), '.vtlStudio.properties')
            writeLines(string, propfile)
          }, error = function(e) {
            if (!is.null(e$jobj)) {
              e$jobj$printStackTrace()
            }
            stop(e)
          })
        }
      }) |> bindEvent(input[[prop$getName()]], ignoreInit = T)
    }
  }

  output$proxyControls <- renderUI({
    ctrls <- lapply(c('Host', 'Port', 'User', 'Password'), function (prop) {
      inputId <- paste0("proxy", prop)
      label <- paste0(prop, ':') 
      value <- J("java.lang.System")$getProperty(paste0("https.proxy", prop))
      if (is.null(value))
        value <- ''
      
      (if (prop == 'Password') passwordInput else textInput)(inputId, label, value)
    })
    
    do.call(tagList, ctrls)
  })
  
  # Proxy controls
  lapply(c('Host', 'Port', 'User', 'Password'), function (prop) {
    inputId <- paste0('proxy', prop)
    observe({
      value <- input[[inputId]]
      output$eng_conf_output <- renderPrint({
        cat(paste('Setting Proxy', prop, 'to', value, '\n'))
        
        if (value == '') {
          J("java.lang.System")$clearProperty(paste0("http.proxy", prop))
          J("java.lang.System")$clearProperty(paste0("https.proxy", prop))
        } else {
          J("java.lang.System")$setProperty(paste0("http.proxy", prop), value)
          J("java.lang.System")$setProperty(paste0("https.proxy", prop), value)
        }
      })
    }) |> bindEvent(input[[inputId]], ignoreInit = T)
  })

  # Download vtl script button
  output$saveas <- downloadHandler(
    filename = function() {
      req(input$sessionID)
      paste0(isolate(input$sessionID), ".vtl")
    }, content = function (file) {
      writeLines(currentSession()$text, file)
    }
  )

  # Toggle demo mode
  observe({
  	VTLSessionManager$clear()
  	if (isTRUE(input$demomode)) {
      VTLSessionManager$kill('test')
      name <- VTLSessionManager$initExampleSessions()
  	} else {
  	  name <- 'test'
  	}
  	updateSelectInput(session = session, inputId = 'sessionID', choices = VTLSessionManager$list(), selected = name)
  }) |> bindEvent(input$demomode)
  
  # load theme list
  observe({
    updateSelectInput(inputId = 'editorTheme', choices = input$themeNames)
  }) |> bindEvent(input$themeNames)
  
  # Initially populate environment list and load properties
  envlistdone <- observe({
    defaultRepository <- J("it.bancaditalia.oss.vtl.config.VTLGeneralProperties")$METADATA_REPOSITORY$getValue()
    updateSelectInput(inputId = 'selectEnv', choices = unlist(environments))
    updateSelectInput(inputId = 'repoClass', choices = repoImpls, selected = defaultRepository)
    output$sortableEnvs <- renderUI({
      sortable::bucket_list(header = NULL, orientation = 'horizontal',
        sortable::add_rank_list(text = "Available", labels = activeEnvs(F)),
        sortable::add_rank_list(input_id = "envs", text = "Active", labels = activeEnvs(T))
      )
    })
    # Single execution only when VTL Studio starts
    envlistdone$destroy()
  })

  # Apply configuration to the active session
  observe({
	currentSession()$refresh()
  }) |> bindEvent(input$applyConfAll, ignoreInit = T)

  # Apply configuration to all active sessions
  observe({
    VTLSessionManager$reload()
  }) |> bindEvent(input$applyConfAll, ignoreInit = T)

  # Environment properties list
  observe({
    output$envprops <- controlsGen(input$selectEnv)
    lapply(configManager$getSupportedProperties(J(input$selectEnv)@jobj), observerGen)
  }) |> bindEvent(input$selectEnv, ignoreInit = T)

  # Repository properties list
  observe({
    output$repoProperties <- controlsGen(input$repoClass)
    lapply(configManager$getSupportedProperties(J(input$repoClass)@jobj), observerGen)

    output$eng_conf_output <- renderPrint({
      vtlProperties$METADATA_REPOSITORY$setValue(req(input$repoClass))
      cat("Set metadata repository to", input$repoClass, "\n")
    })
  }) |> bindEvent(input$repoClass, ignoreInit = T)

  # Save Configuration as...
  output$saveconfas <- downloadHandler(
    filename = ".vtlStudio.properties",
    content = function (file) {
      tryCatch({
        writer <- .jnew("java.io.StringWriter")
        configManager$newManager()$saveConfiguration(writer)
        string <- .jstrVal(writer$toString())
        writeLines(string, file)
      }, error = function(e) {
        if (!is.null(e$jobj)) {
          e$jobj$printStackTrace()
        }
        stop(e)
      })
    }
  )

  # Select dataset to browse
  output$dsNames<- renderUI({
    selectInput(inputId = 'selectDatasets', label = 'Select Node', multiple = F, 
                choices = c('', sort(unlist(currentSession()$getNodes()))), selected ='')
  })

  # render the structure of a dataset
  output$dsStr<- DT::renderDataTable({
    req(input$sessionID)
    req(input$structureSelection)
    jstr = currentSession()$getMetadata(req(input$structureSelection))
    if (jstr %instanceof% "it.bancaditalia.oss.vtl.model.data.ScalarValueMetadata") {
      df <- data.table::transpose(data.frame(c(jstr$getDomain()$toString()), check.names = FALSE))
      colnames(df) <- c("Domain")
      df
    } else if (jstr %instanceof% "it.bancaditalia.oss.vtl.impl.types.dataset.DataStructureBuilder$DataStructureImpl") {
      df <- data.table::transpose(data.frame(lapply(jstr, function(x) {
        c(x$getVariable()$getAlias()$getName(), x$getVariable()$getDomain()$toString(), x$getRole()$getSimpleName()) 
      } ), check.names = FALSE))
      colnames(df) <- c("Name", "Domain", "Role")
      df
    } else {
      data.frame(c("ERROR", check.names = FALSE))
    }
  })
  
  # output dataset lineage 
  output$lineage <- networkD3::renderSankeyNetwork({
    req(input$sessionID)
    req(input$selectDatasets)
    edges <- tryCatch({
        currentSession()$getLineage(input$selectDatasets) 
      }, error = function(e) {
        if (is.null(e$jboj))
          e$jobj$printStackTrace()
        signalCondition(e)
      }
    )
    if (nrow(edges) > 0) {
      vertices <- data.frame(name = unique(c(as.character(edges[,'source']), as.character(edges[,'target']))), stringsAsFactors = F)
      edges[, 'source'] <- match(edges[, 'source'], vertices[, 'name']) - 1
      edges[, 'target'] <- match(edges[, 'target'], vertices[, 'name']) - 1
      graph <- networkD3::sankeyNetwork(Links = edges, Nodes = vertices, Source = 'source', 
                                        Target = 'target', Value = 'value', NodeID = 'name', 
                                        nodeWidth = 40, nodePadding = 20, fontSize = 10)
      return(graph)
    }
    else
      shinyjs::alert(paste("Node", input$selectDatasets, "is a scalar or a source node."))
    
    return(invisible())
  })
  
  # output VTL result  
  output$datasets <- DT::renderDataTable({
    req(input$sessionID)
    req(input$selectDatasets)
    req(input$maxlines)
    maxlines = as.integer(input$maxlines)
    result = NULL
    nodes = evalNode()
    if(length(nodes) > 0){
      ddf = nodes[[1]]
      if(ncol(ddf) >= 1 && names(ddf)[1] != 'Scalar'){
        linesLimit = ifelse(nrow(ddf) > maxlines , yes = maxlines, no = nrow(ddf))
        ddf = ddf[1:linesLimit,]
        #not a scalar, order columns and add component role
        neworder = which(names(ddf) %in% attr(ddf, 'measures'))
        neworder = c(neworder, which(names(ddf) %in% attr(ddf, 'identifiers')))
        if(input$showAttrs){
          neworder = c(neworder, which(!(1:ncol(ddf) %in% neworder)))
        }
        
        names(ddf) = sapply(names(ddf), function(x, ddf) {
          if(x %in% attr(ddf, 'identifiers')){
            return(paste0(x, ' (', 'I', ') '))
          }
          else if(x %in% attr(ddf, 'measures')){
            return(paste0(x, ' (', 'M', ') '))
          }
          else{
            return(x)
          }
        }, ddf)
        
        if(ncol(ddf) > 1){
          result = ddf[,neworder]
        }
        
      }
      else{
        result = ddf
      }
    }
    return(result)
  }, options = list(
    lengthMenu = list(c(50, 1000, -1), c('50', '1000', 'All')),
    pageLength = 10
  ))

  # Disable buttons to create sessions
  observe({
    shinyjs::toggleState("createSession", isTruthy(input$newSession))
    shinyjs::toggleState("dupSession", isTruthy(input$newSession))
  })
  
  # Disable proxy button if host and port not specified
  observe({
    shinyjs::toggleState("setProxy", isTruthy(input$proxyHost) && isTruthy(input$proxyPort))
  })
  
  # Disable navigator and graph if the session was not compiled
  observe({
    shinyjs::toggleCssClass(selector = ".nav-tabs li:nth-child(2)", class = "tab-disabled", condition = !isCompiled())
    shinyjs::toggleCssClass(selector = ".nav-tabs li:nth-child(3)", class = "tab-disabled", condition = !isCompiled())
    if (isCompiled()) {
      vtlSession <- currentSession()
      output$topology <- networkD3::renderForceNetwork({
        vtlSession$getTopology(distance = input$distance)
      })
      #update list of datasets to be explored
      updateSelectInput(session, 'selectDatasets', 'Select Node', c('', vtlSession$getNodes()), '')
      #update list of dataset structures
      updateSelectInput(session, 'structureSelection', 'Select Node', c('', sort(unlist(vtlSession$getNodes()))), '')
    } 
  })

  # Change editor theme
  observe({
    session$sendCustomMessage("editor-theme", input$editorTheme)
  }) |> bindEvent(input$editorTheme)
  
  # Reload the active anvironments from the current session
  observe({
    if (input$navtab == "Engine settings") {
      loadedenvs <- sapply(VTLSessionManager$getOrCreate(req(input$sessionID))$getEnvs(), \(cenv) cenv$getClass()$getName())
      output$sortableEnvs <- renderUI({
        active <- names(environments[unlist(environments) %in% loadedenvs])
        inactive <- names(environments[!(unlist(environments) %in% loadedenvs)])
        sortable::bucket_list(header = NULL, orientation = 'horizontal',
          sortable::add_rank_list(text = "Available", labels = inactive),
          sortable::add_rank_list(input_id = "envs", text = "Active", labels = active),
        )
      })
    }
  }) |> bindEvent(input$navtab)
  
  # Change editor font size
  observe({
    session$sendCustomMessage("editor-fontsize", input$editorFontSize)
  }) |> bindEvent(input$editorFontSize)
  
  # switch VTL session
  observe({
    vtlSession <- currentSession()
    name <- vtlSession$name
    isCompiled(vtlSession$isCompiled())
    #update list of datasets to be explored
    session$sendCustomMessage("editor-text", vtlSession$text)
    session$sendCustomMessage("editor-focus", message = '')
  })

  # Update active environments
  observe({
    vtlProperties$ENVIRONMENT_IMPLEMENTATION$setValue(paste0(unlist(environments[req(input$envs)]), collapse = ","))
    tryCatch({
      writer <- .jnew("java.io.StringWriter")
      configManager$newManager()$saveConfiguration(writer)
      string <- .jstrVal(writer$toString())
      propfile <- file.path(J("java.lang.System")$getProperty("user.home"), '.vtlStudio.properties')
      writeLines(string, propfile)
    }, error = function(e) {
      if (!is.null(e$jobj)) {
        e$jobj$printStackTrace()
      }
      stop(e)
    })
  }) |> bindEvent(input$envs, ignoreInit = T)
    
  # load vtl script
  observe({
    lines = suppressWarnings(readLines(input$scriptFile$datapath))
    lines = paste0(lines, collapse = '\n')
    vtlSession <- VTLSessionManager$getOrCreate(input$scriptFile$name)$setText(lines)
    isCompiled(vtlSession$isCompiled())
    #update current session
    updateSelectInput(session = session, inputId = 'sessionID', choices = VTLSessionManager$list(), selected = input$scriptFile$name)
  }) |> bindEvent(input$scriptFile)
  
  # upload CSV file to GlobalEnv
  observeEvent(input$datafile, {
    datasetName = basename(input$datafile$name)
    data = readLines(con = input$datafile$datapath)
    if(length(data > 1)){
      header = as.character(utils::read.csv(text = data[1], header = F))
      ids1 = which(startsWith(header, prefix = '$'))
      ids2 = which(!startsWith(header, prefix = '#') & !grepl(x = header, pattern = '=', fixed = T))
      ids = c(ids1, ids2)
      measures = which(!startsWith(header, prefix = '#') & !startsWith(header, prefix = '$') & grepl(x = header, pattern = '=', fixed = T))
      names = sub(x=
                    sub(x = 
                          sub(x = header, pattern = '\\#', replacement = '')
                    , pattern = '\\$', replacement = '')
              , pattern = '\\=.*', replacement = '')
      body = utils::read.csv(text = data[-1], header = F, stringsAsFactors = F)
      body = stats::setNames(object = body, nm = names)
      
      #type handling very raw for now, to be refined
      # force strings (some cols could be cast to numeric by R)
      stringTypes = which(grepl(x = header, pattern = 'String', fixed = T))
      body[, stringTypes] = as.character(body[, stringTypes])
      
      attr(x = body, which = 'identifiers') = names[ids]
      attr(x = body, which = 'measures') = names[measures]
      assign(x = datasetName, value = body, envir = .GlobalEnv)
      output$vtl_output <- renderPrint({
        cat(paste('File ', input$datafile$name, 'correctly loaded into R Environment. Dataset name to be used:', datasetName, '\n'))
      })
    }
    else{
      output$vtl_output <- renderPrint({
        message('Error: file ', input$datafile$name, ' is malformed.\n')
      })
    }
  })
  
  # create new session
  observe({
    name <- req(input$newSession)
    vtlSession <- VTLSessionManager$getOrCreate(name)
    isCompiled(vtlSession$isCompiled())
    updateSelectInput(session = session, inputId = 'sessionID', choices = VTLSessionManager$list(), selected = name)
    updateTextInput(session = session, inputId = 'newSession', value = '')
  }) |> bindEvent(input$createSession)
  
  # duplicate session
  observe({
    newName <- req(input$newSession)
    text <- currentSession()$text
    newSession <- VTLSessionManager$getOrCreate(newName)
    newSession$setText(text)
    isCompiled(newSession$isCompiled())
    updateTextInput(session = session, inputId = 'newSession', value = '')
    updateSelectInput(session = session, inputId = 'sessionID', choices = VTLSessionManager$list(), selected = newName)
  }) |> bindEvent(input$dupSession)
  
  # compile VTL code
  observe({
    shinyjs::disable("compile")
    vtlSession <- currentSession()
    statements <- input$vtlStatements
    withProgress(message = 'Compiling...', value = 0, tryCatch({ 
      vtlSession$setText(statements) 
      setProgress(value = 0.5)
      vtlSession$compile()
      isCompiled(T)
      shinyjs::html("vtl_output", cat("Compilation successful.\n"))
      # Update force network
      output$topology <- networkD3::renderForceNetwork(vtlSession$getTopology(distance = input$distance))
      #update list of datasets to be explored
      updateSelectInput(session, 'selectDatasets', 'Select Node', c('', vtlSession$getNodes()), '')
      #update list of dataset structures
      updateSelectInput(session, 'structureSelection', 'Select Node', c('', sort(unlist(vtlSession$getNodes()))), '')
    }, error = function(e) {
      msg <- conditionMessage(e)
      trace <- NULL
      if (is.list(e) && !is.null(e[['jobj']]))
      {
        writer <- .jnew("java.io.StringWriter")
        e$jobj$printStackTrace(.jnew("java.io.PrintWriter", .jcast(writer, "java/io/Writer")))
        trace <- writer$toString()
        msg <- e$jobj$getLocalizedMessage()
      }
      shinyjs::html("vtl_output", paste0('<span style="color: red">Error during compilation: ', 
        msg, '\n', if (is.null(trace)) '' else trace, '\n</span>')
      )
    }, finally = {
      setProgress(value = 1)
      shinyjs::enable("compile")
    }))
  }) |> bindEvent(input$compile)
  
  observeEvent(input$editorText, {
    currentSession()$setText(req(input$editorText))
  })

  output$datasetsInfo <- renderUI({
    req(input$selectDatasets)
    statements <- currentSession()$getStatements()
    statements <- sapply(statements$entrySet(), function (x) {
      stats::setNames(list(x$getValue()), x$getKey()$getName())
    })
    ddf = evalNode()[[1]]
    formula <- statements[[input$selectDatasets]]
    
    return(tags$div(
      tags$p(tags$span("Node"), tags$span(input$selectDatasets), tags$span(paste("(", nrow(ddf), "by", ncol(ddf), ")"))),
      tags$p(tags$span("Rule:"), ifelse(test = is.null(formula), no = formula, yes = 'Source data'))
    ))
  })

  observe({
    conf = readLines(con = input$uploadconf$datapath)
    
    reader <- NULL
    tryCatch({
      reader <- .jnew("java.io.StringReader", conf)
      J("it.bancaditalia.oss.vtl.config.ConfigurationManagerFactory")$loadConfiguration(reader)
    }, finally = {
      if (!is.null(reader)) {
        reader$close()
      }
    })
    VTLSessionManager$reload()
  }) |> bindEvent(input$custom_conf)
}