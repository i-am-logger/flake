#!/usr/bin/env bash
echo "Testing GPG signing with the same environment Git would use..."
echo "GPG_TTY: $GPG_TTY"
echo "SSH_AUTH_SOCK: $SSH_AUTH_SOCK"
echo "Testing direct GPG signing:"
echo "test" | gpg --clearsign
echo "Testing with card status:"
gpg --card-status
echo "Testing key availability:"
gpg -K 3842FC405341B51B
