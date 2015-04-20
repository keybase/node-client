
## Generate keys in batch mode

    ./gpg.sh --gen-keys --batch < gen-keybase-v1.batch

## Verify with a de-facto trusted key (and skip trust DB stuff)

    ./gpg2.sh --trusted-key C71029D229E85B8B --verify m1.sig 
