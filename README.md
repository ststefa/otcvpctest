# Overview

This module contains examples how to manage the OTC VPC feature using terraform. It is split into separate folders with each folder containing a single example.

The **managed** folder contains an example on how to setup a terraform-managed VPC along with peering to another VPC in a different project ("VPC peering"). Peering is equally possible between different tenants (not illustrated here). Two subnets are created in the VPC, one in each AZ. It also configures an example VM which is put inside the VPC AZ1 subnet.

The **unmanaged** folder contains an example on how to use an existing VPC through datasources. It also configures an example VM which is put inside the VPC AZ2 subnet. This example uses the vpc created in the managed example.

The **remotestate** folder contains an example on how to use existing resources through terraform remote state    . It also conofigures an example VM which is put inside the VPC AZ2 subnet. This example reuses all resources created in the unmanaged example (except for the actual VM).
