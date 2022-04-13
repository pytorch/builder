#!/bin/bash

###########################
### prereqs
###########################
# Install Python packages depending on the base OS
ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
case "$ID" in
  ubuntu)
    apt install -y libpciaccess-dev pkg-config
    ;;
  centos)
    yum install -y libpciaccess-devel pkgconfig
    ;;
  *)
    echo "Unable to determine OS..."
    exit 1
    ;;
esac
python3 -m pip install meson ninja

###########################
### clone repo
###########################
GIT_SSL_NO_VERIFY=true git clone https://gitlab.freedesktop.org/mesa/drm.git
pushd drm

###########################
### patch
###########################
patch -p1 <<'EOF'
diff --git a/amdgpu/amdgpu_asic_id.c b/amdgpu/amdgpu_asic_id.c
index a5007ffc..a3627529 100644
--- a/amdgpu/amdgpu_asic_id.c
+++ b/amdgpu/amdgpu_asic_id.c
@@ -22,6 +22,13 @@
  *
  */
 
+#define _XOPEN_SOURCE 700
+#define _LARGEFILE64_SOURCE
+#define _FILE_OFFSET_BITS 64
+#include <ftw.h>
+#include <link.h>
+#include <limits.h>
+
 #include <ctype.h>
 #include <stdio.h>
 #include <stdlib.h>
@@ -34,6 +41,21 @@
 #include "amdgpu_drm.h"
 #include "amdgpu_internal.h"
 
+static char *amdgpuids_path = NULL;
+
+static int check_for_location_of_amdgpuids(const char *filepath, const struct stat *info, const int typeflag, struct FTW *pathinfo)
+{
+	if (typeflag == FTW_F && strstr(filepath, "amdgpu.ids")) {
+		if (NULL != amdgpuids_path) {
+			free(amdgpuids_path);
+		}
+		amdgpuids_path = strdup(filepath);
+		return 0;
+	}
+
+	return 0;
+}
+
 static int parse_one_line(struct amdgpu_device *dev, const char *line)
 {
 	char *buf, *saveptr;
@@ -113,13 +135,48 @@ void amdgpu_parse_asic_ids(struct amdgpu_device *dev)
 	int line_num = 1;
 	int r = 0;
 
-	fp = fopen(AMDGPU_ASIC_ID_TABLE, "r");
+	char self_path[ PATH_MAX ];
+	ssize_t count;
+	ssize_t i;
+
+	fp = NULL;
+	count = readlink( "/proc/self/exe", self_path, PATH_MAX );
+	if (count > 0) {
+		self_path[count] = '\0';
+
+		// replace bin/python with lib
+		for (i=count; i>0; --i) {
+			if (self_path[i] == '/') break;
+			self_path[i] = '\0';
+		}
+		self_path[i] = '\0';
+		for (; i>0; --i) {
+			if (self_path[i] == '/') break;
+			self_path[i] = '\0';
+		}
+		strcat(self_path, "lib");
+
+		if (0 == nftw(self_path, check_for_location_of_amdgpuids, 5, FTW_PHYS)) {
+			if (amdgpuids_path) {
+				fp = fopen(amdgpuids_path, "r");
+				if (!fp) {
+					fprintf(stderr, "%s: %s\n", amdgpuids_path, strerror(errno));
+				}
+			}
+		}
+	}
+
+	if (!fp) {
+
+	fp = fopen(AMDGPU_ASIC_ID_TABLE, "r");
 	if (!fp) {
 		fprintf(stderr, "%s: %s\n", AMDGPU_ASIC_ID_TABLE,
 			strerror(errno));
 		return;
 	}
 
+	}
+
 	/* 1st valid line is file version */
 	while ((n = getline(&line, &len, fp)) != -1) {
 		/* trim trailing newline */
EOF

###########################
### build
###########################
meson builddir --prefix=/opt/amdgpu
pushd builddir
ninja install

popd
popd
