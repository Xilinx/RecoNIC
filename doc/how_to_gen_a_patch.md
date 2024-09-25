# How to Generate a Patch for RecoNIC

## Directory Structure
```
├── RecoNIC
│   └── patches
│       └── open-nic-shell
|           └── rdma_onic.patch
└── gen_patch
    ├── open-nic-shell
    └── original
        └── open-nic-shell
```

## Steps to Generate a Patch

### Prepare Your Customized `open-nic-shell` Repository
Fork [Xilinx/open-nic-shell](https://github.com/Xilinx/open-nic-shell) to your account `ABC`.
2. Clone the forked repository:
  ```sh
  $ cd gen_patch
  $ git clone https://github.com/ABC/open-nic-shell.git
  $ cd open-nic-shell
  $ git checkout 520cf7716196765c7cb312d950f3f8b2164bd02d
  $ git apply --whitespace=fix ../../RecoNIC/patches/open-nic-shell/rdma_onic.patch
  ```
Add your new changes to this repository.

### Prepare Original `open-nic-shell` Repository

  ```sh
  $ mkdir -p gen_patch/original
  $ cd gen_patch/original
  $ git clone https://github.com/Xilinx/open-nic-shell.git
  $ cd open-nic-shell
  $ git checkout 520cf7716196765c7cb312d950f3f8b2164bd02d
  $ git checkout -b compare-upstream
  ```

### Generate the Patch
Add the remote upstream repository and fetch changes:
  ```sh
  $ cd gen_patch/original/open-nic-shell
  $ git remote add upstream https://github.com/ABC/open-nic-shell.git
  $ git fetch upstream
  ```
Generate the patch:
  ```sh
  $ git diff HEAD upstream/your_branch_name > rdma_onic.patch
  ```
Copy the patch to the appropriate directory:
  ```sh
  $ cp rdma_onic.patch ../../../RecoNIC/patches/open-nic-shell/
  ```

### Test the Patch
You need to first obtain the submodule, open-nic-shell, in the RecoNIC, if you haven't done it before.
  ```sh
  $ cd RecoNIC
  $ git submodule update --init base_nics/open-nic-shell
  ```
Generate the base NIC with the patch generated:
  ```sh
  $ cd ./scripts
  $ ./gen_base_nic.sh
  ```

### Cleaning Up Dirty Submodule
If the submodule is dirty, you can use the following commands to clean up the folder:
```sh
$ cd your_path_to_submodule
$ git checkout -- .
$ git clean -fd
```

Please make sure you don't have any errors or trailing whitespace. If you do, modify your repository and go back to step 3.
