# Daphne Virlar-Knight
# March 22 2022


# Ticket 24232: https://support.nceas.ucsb.edu/rt/Ticket/Display.html?id=24232&results=6d65329121909bbd7a1f8dd92a11ead3

# Dataset: https://arcticdata.io/catalog/view/urn%3Auuid%3A48ebeb1f-2288-423b-9dc6-500d72821563


## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- general setup -- ##
# run token in console


# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")


# Get the package
packageId <- "resource_map_urn:uuid:06c29991-12f2-4b12-b544-862b4520121e"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)


# Get the metadata id
xml <- selectMember(dp, "sysmeta@fileName", ".xml")


# Read in the metadata
doc <- read_eml(getObject(d1c@mn, xml))




## -- Find Reference Files -- ##
# Reference files are those that don't contain vars7p3
# These have attribute tables that need to be copied over to other datasets

# Find ref files
which_in_eml(doc$dataset$otherEntity, "entityName", 
             function(x) {
               grepl("vars7p3.mat", x) # looking for the reference files
             })
# [1] 1 2 3 4 5

doc$dataset$otherEntity[[10]]$entityName
# [1] "FESOM_vars.mat"    --> 10
# [1] "MIT_vars.mat"      --> 9
# [1] "MIT10_vars.mat"    --> 8
# [1] "NorESM_vars.mat"   --> 7
# [1] "UALBERTA_vars.mat" --> 6


id_list <- c("FESOM", "MIT", "MIT10", "NorESM", "UALBERTA")


for (i in 1:5){
  # Assign reference attributes and description
  ref_attList <- doc$dataset$otherEntity[[i]]$attributeList
  ref_desc <- doc$dataset$otherEntity[[i]]$entityDescription
  
  # Create reference id
  doc$dataset$otherEntity[[i]]$attributeList$id <-id_list[i]
  
  for (j in 10:6){
    # add attribute list
    doc$dataset$otherEntity[[j]]$attributeList <- ref_attList
    doc$dataset$otherEntity[[j]]$attributeList <- list(references = id_list[i])
    
    # add description
    doc$dataset$otherEntity[[j]]$entityDescription <- ref_desc
  }
}

eml_validate(doc)



## -- Update package -- ##
eml_path <- "~/Scratch/Beaufort_Gyre_CRF_experiments_sea_ice.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

packageId <- uploadDataPackage(d1c, dp, public = FALSE,
                               accessRules = myAccessRules, quiet = FALSE)
