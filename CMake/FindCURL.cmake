include(FetchContent)

if(${BUILD_CURL_FROM_SOURCE})
    message("Add and build standalone libcurl")
    include(FetchContent)
    FetchContent_Declare(
        curl_bundle
        GIT_REPOSITORY https://github.com/curl/curl.git
        GIT_TAG curl-7_42_1
        GIT_PROGRESS 1)

    FetchContent_GetProperties(curl_bundle)

    # In libcurl, CMakeLists build static lib is broken add build command via
    # make
    if(NOT TARGET libcurl_static_build)
        if (NOT curl_bundle_POPULATED)
            FetchContent_Populate(curl_bundle)
        endif()
        add_custom_command(
            OUTPUT ${curl_bundle_BINARY_DIR}/lib/libcurl.a
            WORKING_DIRECTORY ${curl_bundle_SOURCE_DIR}
            COMMAND
                export CC=${CMAKE_C_COMPILER} &&
                export CXX=${CMAKE_CXX_COMPILER} &&
                export LD=${CMAKE_LINKER} &&
                export CFLAGS=-fPIC &&
                autoreconf -i && sh configure --with-openssl --without-libssh2
                --enable-static --enable-shared=no --enable-optimize
                --enable-symbol-hiding --disable-manual --without-libidn
                --disable-ftp --disable-file --disable-ldap --disable-ldaps
                --disable-rtsp --disable-dict --disable-telnet --disable-tftp
                --disable-pop3 --disable-imap --disable-smb --disable-smtp
                --disable-gopher --without-nghttp2 --enable-http
                --with-pic=PIC
                --prefix=${curl_bundle_BINARY_DIR} && make -j && make install)
        add_custom_target(libcurl_static_build
                          DEPENDS ${curl_bundle_BINARY_DIR}/lib/libcurl.a)
    endif()

    set(CURL_FOUND yes)
    set(CURL_LIBRARY ${curl_bundle_BINARY_DIR}/lib/libcurl.a)
    set(CURL_THIRDPARTY_DEPS crypto ssl z)
    set(CURL_LIBRARIES ${CURL_LIBRARY} ${CURL_THIRDPARTY_DEPS})
    set(CURL_INCLUDE_DIR ${curl_bundle_BINARY_DIR}/include)
    set(CURL_INCLUDE_DIRS ${CURL_INCLUDE_DIR})
    set(CURL_VERSION_STRING 7.42.1)

    # Use libcurl static lib instead of cmake defined shared lib
    if(NOT TARGET CURL::libcurl)
        add_library(CURL::libcurl UNKNOWN IMPORTED)
    endif()
    add_dependencies(CURL::libcurl libcurl_static_build)
    message("${CURL_LIBRARY}")
    set_target_properties(
        CURL::libcurl
        PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C"
                   IMPORTED_LOCATION "${CURL_LIBRARY}"
                   INTERFACE_INCLUDE_DIRECTORIES "${CURL_INCLUDE_DIRS}"
                   INTERFACE_LINK_LIBRARIES "${CURL_THIRDPARTY_DEPS}")
else()
    include(${CMAKE_ROOT}/Modules/FindCURL.cmake)
endif()
