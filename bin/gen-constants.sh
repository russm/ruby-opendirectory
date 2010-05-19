#!/bin/sh

# build a file full of OD constants since Apple doesn't include bridge
# support files for CFOpenDirectory.framework... bah...

# we download 'em from the net since that's the only copy of
# CFOpenDirectoryConstants.c I can find...


target_dir=$(dirname "$0")/../lib/opendirectory
target_file=${target_dir}/constants.rb

echo ===== $target_file

cat <<HEADER > $target_file
module OpenDirectory
  module Constants
HEADER

# enum constants
curl 'http://www.opensource.apple.com/source/OpenDirectory/OpenDirectory-57/CFOpenDirectoryConstants.h?txt' | \
  perl -ne 'next unless /^\s*kOD([A-Za-z]+)\s*=\s*(0x[0-9a-fA-F]+)/; print qq(    $1 = $2\n)' >> $target_file

# string "constants"
curl 'http://www.opensource.apple.com/source/OpenDirectory/OpenDirectory-57/CFOpenDirectoryConstants.c?txt' | \
  perl -ne 'next unless /^\s*CFStringRef\s+kOD([[:alpha:]]+)\s*=\s*CFSTR\((".*?")\)/; print qq(    $1 = $2\n)' | \
  sort >> $target_file

cat <<FOOTER >> $target_file
  end
end
FOOTER
