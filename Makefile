TARGET = iphone:11.2:11.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NerdMode

NerdMode_FILES = Tweak.x
NerdMode_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
