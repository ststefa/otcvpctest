# Overview

This module contains examples how to manage the OTC VPC feature using terraform. It is split into "managed" and "unmanaged" folders.

The **managed** folder contains an example on how to setup a terraform-managed VPC along with peering to another VPC in a different project ("VPC peering"). Peering is even possible between different tenants. Two subnets are created in the vpc, one in each AZ. It also configures an example VM which is put inside the VPC AZ1 subnet.

The **unmanaged** folder contains an example on how to use an existing VPC through datasources. It also conofigures an example VM which is put inside the VPC AZ2 subnet. This example uses the vpc created in the managed example.
