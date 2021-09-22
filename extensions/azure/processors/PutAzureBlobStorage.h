/**
 * @file PutAzureBlobStorage.h
 * PutAzureBlobStorage class declaration
 *
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#pragma once

#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "core/Property.h"
#include "core/logging/Logger.h"
#include "core/logging/LoggerConfiguration.h"
#include "storage/BlobStorage.h"
#include "AzureStorageProcessorBase.h"

class PutAzureBlobStorageTestsFixture;

namespace org::apache::nifi::minifi::azure::processors {

class PutAzureBlobStorage final : public AzureStorageProcessorBase {
 public:
  // Supported Properties
  static const core::Property ContainerName;
  static const core::Property StorageAccountName;
  static const core::Property StorageAccountKey;
  static const core::Property SASToken;
  static const core::Property CommonStorageAccountEndpointSuffix;
  static const core::Property ConnectionString;
  static const core::Property Blob;
  static const core::Property CreateContainer;

  // Supported Relationships
  static const core::Relationship Failure;
  static const core::Relationship Success;

  explicit PutAzureBlobStorage(const std::string& name, const minifi::utils::Identifier& uuid = minifi::utils::Identifier())
    : PutAzureBlobStorage(name, uuid, nullptr) {
  }

  ~PutAzureBlobStorage() override = default;

  void initialize() override;
  void onSchedule(const std::shared_ptr<core::ProcessContext> &context, const std::shared_ptr<core::ProcessSessionFactory> &sessionFactory) override;
  void onTrigger(const std::shared_ptr<core::ProcessContext> &context, const std::shared_ptr<core::ProcessSession> &session) override;

  class ReadCallback : public InputStreamCallback {
   public:
    ReadCallback(uint64_t flow_size, storage::BlobStorage& blob_storage_wrapper, const std::string &blob_name)
      : flow_size_(flow_size)
      , blob_storage_wrapper_(blob_storage_wrapper)
      , blob_name_(blob_name) {
    }

    int64_t process(const std::shared_ptr<io::BaseStream>& stream) override {
      std::vector<uint8_t> buffer;
      size_t read_ret = stream->read(buffer, flow_size_);
      if (io::isError(read_ret) || read_ret != flow_size_) {
        return -1;
      }

      result_ = blob_storage_wrapper_.uploadBlob(blob_name_, buffer.data(), flow_size_);
      if (!result_) {
        return read_ret;
      }
      return result_->length;
    }

    std::optional<storage::UploadBlobResult> getResult() const {
      return result_;
    }

   private:
    uint64_t flow_size_;
    storage::BlobStorage &blob_storage_wrapper_;
    std::string blob_name_;
    std::optional<storage::UploadBlobResult> result_ = std::nullopt;
  };

 private:
  friend class ::PutAzureBlobStorageTestsFixture;

  explicit PutAzureBlobStorage(const std::string& name, const minifi::utils::Identifier& uuid, std::unique_ptr<storage::BlobStorage> blob_storage_wrapper)
    : AzureStorageProcessorBase(name, uuid, logging::LoggerFactory<PutAzureBlobStorage>::getLogger())
    , blob_storage_wrapper_(std::move(blob_storage_wrapper)) {
  }

  static std::string getAzureConnectionStringFromProperties(
    const std::shared_ptr<core::ProcessContext> &context,
    const std::shared_ptr<core::FlowFile> &flow_file);
  std::string getConnectionString(
    const std::shared_ptr<core::ProcessContext> &context,
    const std::shared_ptr<core::FlowFile> &flow_file) const;
  void createAzureStorageClient(const std::string &connection_string, const std::string &container_name);

  std::unique_ptr<storage::BlobStorage> blob_storage_wrapper_;
  bool create_container_ = false;
};

}  // namespace org::apache::nifi::minifi::azure::processors
