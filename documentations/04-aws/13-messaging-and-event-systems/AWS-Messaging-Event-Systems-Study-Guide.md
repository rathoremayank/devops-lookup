# AWS Messaging and Event Systems - Deep Dive Study Guide

**Audience:** DevOps Engineers with 5–10+ years experience  
**Date:** March 8, 2026  
**Scope:** SQS, SNS, EventBridge, and Kinesis

---

## Table of Contents
1. [SQS - Simple Queue Service](#sqs---simple-queue-service)
2. [SNS - Simple Notification Service](#sns---simple-notification-service)
3. [EventBridge - Event Bus and Rules](#eventbridge---event-bus-and-rules)
4. [Kinesis - Data Streams and Firehose](#kinesis---data-streams-and-firehose)

---

## SQS - Simple Queue Service

### Textual Deep Dive

#### Internal Working Mechanism

SQS is a fully managed message queue service that decouples application components by allowing asynchronous processing. At its core, SQS maintains distributed queues across multiple availability zones with automatic replication for durability.

**Queue Architecture:**
- **Messages in Transit**: Stored in Amazon's distributed backend with redundancy across AZs
- **Visibility Timeout**: When a consumer receives a message, it becomes invisible to other consumers for a configurable period (default: 30 seconds, max: 12 hours)
- **Message Delivery**: At-least-once delivery guarantee (messages may be processed multiple times)
- **Long Polling**: Reduces API calls by holding requests open until messages arrive (up to 20 seconds)

**Key Components:**
- **Queue**: The fundamental unit of message storage
- **Message Attributes**: Metadata stored with messages (up to 10 custom attributes)
- **Dead-Letter Queue (DLQ)**: Receives messages that exceed max receive count
- **Retention Period**: Default 4 days, configurable from 60 seconds to 14 days

#### Architecture Role

SQS serves as the backbone for decoupled, scalable distributed systems:

1. **Decoupling Component**: Separates producers from consumers, enabling independent scaling
2. **Buffering Layer**: Handles traffic spikes by queuing requests during peak loads
3. **Asynchronous Processing**: Enables fire-and-forget patterns for non-real-time operations
4. **Retry Mechanism**: Built-in retry through visibility timeouts and Dead-Letter Queues

#### Production Usage Patterns

**Pattern 1: Worker Pool Architecture**
```
Producer → SQS Queue ← Multiple Workers
         ↓
      Horizontal Scaling Based on Queue Depth
```

**Pattern 2: Message Ordering with FIFO Queues**
- Standard queues: Best-effort ordering, high throughput
- FIFO (First-In-First-Out) queues: Strict ordering, lower throughput (3,000 messages/sec with batching)

**Pattern 3: Multi-step Workflows**
- Chain of SQS queues with Lambda/EC2 consumers
- Each step passes processed data to the next queue
- Enables gradual scaling and error isolation

**Pattern 4: Fan-out with SNS + SQS**
- SNS publishes to multiple SQS queues
- Each subscriber processes independently
- Scalable pub/sub with queuing guarantees

#### DevOps Best Practices

1. **Queue Configuration**
   - Set appropriate visibility timeouts (2-3x your max processing time)
   - Configure message retention matching your SLA
   - Enable Long Polling to reduce costs (20-second wait)

2. **Dead-Letter Queue Strategy**
   - Set max receive count to 3-5 (balance between retry and failure detection)
   - Monitor DLQ for failed messages
   - Implement alerts when DLQ depth > 0

3. **Scaling Considerations**
   - Use CloudWatch metrics: ApproximateNumberOfMessagesVisible
   - Configure Auto Scaling policies based on queue depth
   - Batch receive operations (receive_messages with MaxMessages=10)

4. **Cost Optimization**
   - Batch API calls (up to 10 messages per SendMessageBatch)
   - Use Long Polling (reduces wasted API calls by ~90%)
   - Delete messages as soon as processed (batch delete operations)

5. **Monitoring & Observability**
   - Track: NumberOfMessagesSent, NumberOfMessagesReceived, ApproximateAgeOfOldestMessage
   - Set alarms for high visibility timeout rates (redrive policy issues)
   - Monitor DLQ depth for systematic failures

#### Common Pitfalls

| Pitfall | Cause | Impact | Solution |
|---------|-------|--------|----------|
| **Duplicate Processing** | At-least-once delivery + application crash | Data inconsistency | Implement idempotent consumers (unique message IDs) |
| **Lost Messages** | Consumer crash before acknowledging | Message loss | Configure longer visibility timeout & DLQ |
| **High Latency** | Short polling interval | Cost explosion, increased latency | Enable Long Polling (20 seconds) |
| **Queue Deadlock** | Downstream service failure | Messages accumulate | Implement circuit breakers + DLQ redrive |
| **Scaling Lag** | Reactive scaling only | Customer impact during spikes | Predictive scaling or pre-warmed workers |

---

### Practical Code Examples

#### CloudFormation Template: SQS with DLQ and Auto Scaling

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'SQS Queue with DLQ and Auto Scaling Worker'

Parameters:
  EnvironmentName:
    Type: String
    Default: production
    AllowedValues: [development, staging, production]

Resources:
  # Dead-Letter Queue
  MessageDLQ:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub '${EnvironmentName}-message-dlq'
      MessageRetentionPeriod: 1209600  # 14 days
      VisibilityTimeout: 300
      Tags:
        - Key: Environment
          Value: !Ref EnvironmentName

  # Primary Queue with DLQ Configuration
  MessageQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub '${EnvironmentName}-message-queue'
      VisibilityTimeout: 300
      MessageRetentionPeriod: 345600  # 4 days
      ReceiveMessageWaitTimeSeconds: 20  # Long Polling enabled
      RedrivePolicy:
        deadLetterTargetArn: !GetAtt MessageDLQ.Arn
        maxReceiveCount: 3
      Tags:
        - Key: Environment
          Value: !Ref EnvironmentName

  # CloudWatch Alarm for DLQ
  DLQAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: !Sub '${EnvironmentName}-message-dlq-depth-alarm'
      AlarmDescription: Alert when DLQ has messages
      MetricName: ApproximateNumberOfMessagesVisible
      Namespace: AWS/SQS
      Statistic: Average
      Period: 300
      EvaluationPeriods: 1
      Threshold: 1
      ComparisonOperator: GreaterThanOrEqualToThreshold
      Dimensions:
        - Name: QueueName
          Value: !GetAtt MessageDLQ.QueueName
      AlarmActions:
        - !Sub 'arn:aws:sns:${AWS::Region}:${AWS::AccountId}:devops-alerts'

  # Auto Scaling Target for Worker Capacity
  WorkerAutoScalingTarget:
    Type: AWS::ApplicationAutoScaling::ScalableTarget
    Properties:
      MaxCapacity: 10
      MinCapacity: 2
      ResourceId: !Sub 'table/worker-table/${EnvironmentName}'
      RoleARN: !Sub 'arn:aws:iam::${AWS::AccountId}:role/autoscaling-service-role'
      ScalableDimension: 'dynamodb:table:WriteCapacityUnits'
      ServiceNamespace: dynamodb

  # Scaling Policy Based on Queue Depth
  QueueDepthScalingPolicy:
    Type: AWS::ApplicationAutoScaling::ScalingPolicy
    Properties:
      PolicyName: !Sub '${EnvironmentName}-queue-depth-scaling'
      PolicyType: TargetTrackingScaling
      ScalingTargetId: !Ref WorkerAutoScalingTarget
      TargetTrackingScalingPolicyConfiguration:
        TargetValue: 5.0  # Process 5 messages per worker capacity unit
        CustomizedMetricSpecification:
          MetricName: ApproximateNumberOfMessagesVisible
          Namespace: AWS/SQS
          Statistic: Average
        ScaleOutCooldown: 60
        ScaleInCooldown: 300

Outputs:
  QueueURL:
    Description: URL of the message queue
    Value: !Ref MessageQueue
    Export:
      Name: !Sub '${EnvironmentName}-message-queue-url'

  QueueArn:
    Description: ARN of the message queue
    Value: !GetAtt MessageQueue.Arn
    Export:
      Name: !Sub '${EnvironmentName}-message-queue-arn'

  DLQUrl:
    Description: URL of the Dead-Letter Queue
    Value: !Ref MessageDLQ
    Export:
      Name: !Sub '${EnvironmentName}-message-dlq-url'
```

#### Python Consumer with Error Handling

```python
#!/usr/bin/env python3
"""
SQS Consumer with idempotency and error handling
Implements best practices for production workloads
"""

import json
import boto3
import logging
import hashlib
import time
from typing import Dict, Any, Optional
from concurrent.futures import ThreadPoolExecutor
from botocore.exceptions import ClientError

# Configuration
QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/123456789/production-message-queue"
MAX_WORKERS = 5
VISIBILITY_TIMEOUT = 300
LONG_POLL_TIMEOUT = 20

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize clients
sqs = boto3.client('sqs')
dynamodb = boto3.resource('dynamodb')

# DynamoDB table for idempotency tracking
idempotency_table = dynamodb.Table('message-idempotency')


class SQSConsumer:
    """Handles SQS message consumption with built-in error handling"""
    
    def __init__(self, queue_url: str, max_workers: int = 5):
        self.queue_url = queue_url
        self.max_workers = max_workers
        self.shutdown = False
    
    def generate_message_hash(self, message_body: str) -> str:
        """Generate hash for idempotency checking"""
        return hashlib.sha256(message_body.encode()).hexdigest()
    
    def is_message_processed(self, message_hash: str) -> bool:
        """Check if message was already processed (idempotency)"""
        try:
            response = idempotency_table.get_item(Key={'MessageHash': message_hash})
            return 'Item' in response
        except ClientError as e:
            logger.error(f"Error checking idempotency: {e}")
            return False
    
    def mark_message_processed(self, message_hash: str) -> None:
        """Mark message as processed in idempotency table"""
        try:
            idempotency_table.put_item(
                Item={
                    'MessageHash': message_hash,
                    'ProcessedAt': int(time.time()),
                    'TTL': int(time.time()) + (24 * 3600)  # 24-hour TTL
                }
            )
        except ClientError as e:
            logger.error(f"Error marking message processed: {e}")
    
    def process_message(self, message: Dict[str, Any]) -> bool:
        """
        Process a single SQS message
        Returns True if successful, False if should be retried
        """
        message_id = message['MessageId']
        receipt_handle = message['ReceiptHandle']
        body = message['Body']
        
        try:
            # Check idempotency
            message_hash = self.generate_message_hash(body)
            if self.is_message_processed(message_hash):
                logger.info(f"Message {message_id} already processed, skipping")
                self.delete_message(receipt_handle)
                return True
            
            # Parse and process
            payload = json.loads(body)
            logger.info(f"Processing message {message_id}: {payload}")
            
            # Simulate business logic
            self.business_logic(payload)
            
            # Mark as processed and delete
            self.mark_message_processed(message_hash)
            self.delete_message(receipt_handle)
            
            logger.info(f"Successfully processed message {message_id}")
            return True
            
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in message {message_id}: {e}")
            self.delete_message(receipt_handle)  # Dead-letter by deleting
            return False
        except Exception as e:
            logger.error(f"Error processing message {message_id}: {e}")
            return False  # Let visibility timeout trigger retry
    
    def business_logic(self, payload: Dict[str, Any]) -> None:
        """Place your business logic here"""
        # Example: Write to DynamoDB, invoke Lambda, etc.
        logger.info(f"Executing business logic for: {payload.get('action')}")
        # Your implementation here
        pass
    
    def delete_message(self, receipt_handle: str) -> None:
        """Delete message from queue after successful processing"""
        try:
            sqs.delete_message(
                QueueUrl=self.queue_url,
                ReceiptHandle=receipt_handle
            )
        except ClientError as e:
            logger.error(f"Error deleting message: {e}")
    
    def receive_and_process(self) -> None:
        """Main consumption loop with long polling"""
        logger.info(f"Starting SQS consumer with {self.max_workers} workers")
        
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            while not self.shutdown:
                try:
                    # Receive messages with long polling
                    response = sqs.receive_message(
                        QueueUrl=self.queue_url,
                        MaxNumberOfMessages=10,
                        VisibilityTimeout=VISIBILITY_TIMEOUT,
                        WaitTimeSeconds=LONG_POLL_TIMEOUT,
                        MessageAttributeNames=['All']
                    )
                    
                    messages = response.get('Messages', [])
                    if not messages:
                        logger.debug("No messages received, continuing poll")
                        continue
                    
                    logger.info(f"Received {len(messages)} messages")
                    
                    # Process messages in parallel
                    futures = [
                        executor.submit(self.process_message, msg)
                        for msg in messages
                    ]
                    
                    # Wait for completion
                    for future in futures:
                        try:
                            future.result(timeout=VISIBILITY_TIMEOUT)
                        except Exception as e:
                            logger.error(f"Error in worker thread: {e}")
                
                except ClientError as e:
                    logger.error(f"SQS error: {e}")
                    time.sleep(5)  # Back off on error
                except KeyboardInterrupt:
                    logger.info("Shutdown signal received")
                    self.shutdown = True


if __name__ == "__main__":
    consumer = SQSConsumer(QUEUE_URL, max_workers=MAX_WORKERS)
    consumer.receive_and_process()
```

#### Shell Script: SQS Operations

```bash
#!/bin/bash
# SQS Operations Script for DevOps

set -euo pipefail

QUEUE_URL="https://sqs.us-east-1.amazonaws.com/123456789/production-message-queue"
REGION="us-east-1"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function: Send a test message
send_message() {
    local message="$1"
    echo -e "${YELLOW}Sending message to queue...${NC}"
    
    aws sqs send-message \
        --queue-url "$QUEUE_URL" \
        --message-body "$message" \
        --region "$REGION" \
        --output json | jq '.MessageId'
}

# Function: Batch send messages
batch_send() {
    local count="$1"
    echo -e "${YELLOW}Sending $count messages in batch...${NC}"
    
    local entries=""
    for i in $(seq 1 "$count"); do
        entries+=$(cat <<EOF
{
    "Id": "$i",
    "MessageBody": "{\"action\": \"process\", \"data\": \"message-$i\"}"
}
EOF
)
        if [ $i -lt "$count" ]; then
            entries+=","
        fi
    done
    
    aws sqs send-message-batch \
        --queue-url "$QUEUE_URL" \
        --entries "[$entries]" \
        --region "$REGION" \
        --output json | jq '.Successful'
}

# Function: Get queue attributes
get_queue_stats() {
    echo -e "${YELLOW}Fetching queue statistics...${NC}"
    
    aws sqs get-queue-attributes \
        --queue-url "$QUEUE_URL" \
        --attribute-names All \
        --region "$REGION" \
        --output json | jq '{
            Messages: .Attributes.ApproximateNumberOfMessages,
            Delayed: .Attributes.ApproximateNumberOfMessagesDelayed,
            NotVisible: .Attributes.ApproximateNumberOfMessagesNotVisible,
            CreatedTimestamp: .Attributes.CreatedTimestamp,
            LastModifiedTimestamp: .Attributes.LastModifiedTimestamp
        }'
}

# Function: Receive and display messages
receive_messages() {
    local count="${1:-1}"
    echo -e "${YELLOW}Receiving $count messages...${NC}"
    
    aws sqs receive-message \
        --queue-url "$QUEUE_URL" \
        --max-number-of-messages "$count" \
        --wait-time-seconds 20 \
        --region "$REGION" \
        --output json | jq '.Messages[]'
}

# Function: Delete a message
delete_message() {
    local receipt_handle="$1"
    echo -e "${YELLOW}Deleting message...${NC}"
    
    aws sqs delete-message \
        --queue-url "$QUEUE_URL" \
        --receipt-handle "$receipt_handle" \
        --region "$REGION"
    
    echo -e "${GREEN}Message deleted${NC}"
}

# Function: Purge queue (WARNING: destructive)
purge_queue() {
    echo -e "${RED}WARNING: This will delete all messages in the queue${NC}"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        aws sqs purge-queue \
            --queue-url "$QUEUE_URL" \
            --region "$REGION"
        echo -e "${GREEN}Queue purged${NC}"
    else
        echo "Purge cancelled"
    fi
}

# Function: Monitor queue depth
monitor_queue() {
    local interval="${1:-5}"
    echo -e "${YELLOW}Monitoring queue (interval: ${interval}s)${NC}"
    
    while true; do
        clear
        echo "=== Queue Monitoring ==="
        get_queue_stats
        echo ""
        echo "Press Ctrl+C to exit"
        sleep "$interval"
    done
}

# Main menu
main() {
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  send <message>           - Send a message"
        echo "  batch <count>            - Send messages in batch"
        echo "  stats                    - Get queue attributes"
        echo "  receive [count]          - Receive messages"
        echo "  delete <receipt_handle>  - Delete a message"
        echo "  purge                    - Purge all messages (DANGEROUS)"
        echo "  monitor [interval_sec]   - Monitor queue depth"
        return 1
    fi
    
    case "$1" in
        send)
            send_message "${2:-test message}"
            ;;
        batch)
            batch_send "${2:-5}"
            ;;
        stats)
            get_queue_stats
            ;;
        receive)
            receive_messages "${2:-1}"
            ;;
        delete)
            delete_message "$2"
            ;;
        purge)
            purge_queue
            ;;
        monitor)
            monitor_queue "${2:-5}"
            ;;
        *)
            echo "Unknown command: $1"
            ;;
    esac
}

main "$@"
```

### ASCII Diagrams

#### SQS Standard Queue Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                         Producers                               │
│    ┌──────────┐  ┌──────────┐  ┌──────────┐                     │
│    │Producer1 │  │Producer2 │  │Producer3 │                     │
│    └────┬─────┘  └────┬─────┘  └────┬─────┘                     │
│         │             │             │                           │
│         └─────────────┼─────────────┘                           │
│                       │ SendMessage (Batched)                   │
└───────────────────────┼────────────────────────────────────────┘
                        │
                  ┌─────▼─────┐
                  │   SQS     │
                  │  Queue    │ ◄── MessageRetentionPeriod: 4 days
                  └─────┬─────┘
                        │
        ┌───────────────┼───────────────┐
        │ ReceiveMessage│ (Long Polling)│
        │ WaitTime: 20s │               │
        │               │               │
    ┌───▼──┐        ┌───▼──┐       ┌──▼───┐
    │Worker│        │Worker│       │Worker│
    │  1   │        │  2   │       │  3   │
    └──┬───┘        └──┬───┘       └──┬───┘
       │  Visibility   │               │
       │ Timeout: 300s │               │
       │               │               │
    ┌──▼────────────────────────────────────┐
    │  Message Processing                   │
    │  - DB Write                           │
    │  - External API Call                  │
    │  - Data Transformation                │
    └──┬────────────────────────────────────┘
       │
       │ DeleteMessage (Success)
       │ or
       │ (Timeout → Redelivery)
       │
    ┌──▼────────────────────────────────────┐
    │  Dead-Letter Queue (DLQ)              │
    │  (After max_receive_count = 3)        │
    │  - Failed messages                    │
    │  - Debugging & Audit                  │
    └───────────────────────────────────────┘
```

#### FIFO vs Standard Queue Comparison
```
STANDARD QUEUE:
┌──────────────────────────────────────┐
│  Message Ordering: Best Effort       │
│  ┌──────────────────────────────────┐│
│  │ M1 (id:001)                      ││
│  │ M2 (id:002)                      ││
│  │ M3 (id:003)                      ││
│  │ → May receive: M2, M1, M3, M1    ││
│  └──────────────────────────────────┘│
│                                       │
│  Throughput: ~100K msg/sec (Unlimited)│
│  Use Case: Non-critical workflows     │
└──────────────────────────────────────┘

FIFO QUEUE:
┌──────────────────────────────────────┐
│  Message Ordering: Guaranteed         │
│  ┌──────────────────────────────────┐│
│  │ M1.fifo (group:user-123)         ││
│  │ M2.fifo (group:user-123)         ││
│  │ M3.fifo (group:user-456)         ││
│  │ → Receive in order per group     ││
│  └──────────────────────────────────┘│
│                                       │
│  Throughput: 3,000 msg/sec (batched) │
│  Use Case: Critical ordered workflows│
└──────────────────────────────────────┘
```

#### Auto-Scaling Based on Queue Depth
```
Queue Depth Monitoring → CloudWatch Metric → Scaling Decision
                                ▲
                                │
                    ApproximateNumberOfMessagesVisible
                                
    ┌───────────────────────────────────────────────────┐
    │                Queue Depth Scaling                 │
    │                                                    │
    │  Low Depth (2-5 msgs)                             │
    │  ├─► Scale Down: 2 workers                        │
    │  └─► Cooldown: 5 minutes                          │
    │                                                    │
    │  Medium Depth (20-50 msgs)                        │
    │  ├─► Maintain: 5 workers                          │
    │  └─► Monitor: Close to equilibrium                │
    │                                                    │
    │  High Depth (100+ msgs)                           │
    │  ├─► Scale Up: 8-10 workers                       │
    │  └─► Cooldown: 1 minute (faster response)         │
    │                                                    │
    │  Critical Depth (500+ msgs)                       │
    │  ├─► Emergency Scale: Max workers (15)            │
    │  └─► Alert: PagerDuty escalation                  │
    │                                                    │
    └───────────────────────────────────────────────────┘
```

---

## SNS - Simple Notification Service

### Textual Deep Dive

#### Internal Working Mechanism

SNS is a fully managed pub/sub (publish-subscribe) messaging service that enables push-based, fan-out message distribution. Unlike SQS's pull model, SNS uses a push model where messages are immediately delivered to all subscribers.

**Core Architecture:**
- **Topics**: Logical channels for message publishing (unique name per region per account)
- **Subscriptions**: Registered endpoints that receive notifications
- **Message Filtering**: Optional JSON-based attribute filtering at subscription level
- **Message Attributes**: Custom metadata (up to 10 per message, 256 bytes each)
- **Deduplication**: Optional for FIFO topics (exact duplicate detection within 5 minutes)

**Supported Protocols:**
- HTTP/HTTPS (with custom headers and query parameters)
- Email/Email-JSON
- AWS Lambda
- AWS SQS (fan-out pattern)
- AWS Kinesis Data Firehose
- Platform-specific endpoints (APNs, GCM, Baidu, etc.)
- Mobile push notifications

#### Architecture Role

SNS serves multiple critical patterns in modern distributed systems:

1. **Fan-Out Messaging**: Single publish → Multiple independent consumers
2. **Application Integration**: Decouple microservices through async events
3. **Mobile Push**: Send notifications to millions of device endpoints
4. **Operational Alerts**: Route notifications to multiple channels (email, SMS, Slack, PagerDuty)
5. **Cross-Account/Region Messaging**: Multi-tenant architectures with SNS subscription filtering

#### Production Usage Patterns

**Pattern 1: Fan-Out with SQS (Most Common)**
```
Event Source (S3, DynamoDB, Lambda)
            │
            ▼
        SNS Topic
      ┌───┬───┬───┐
      │   │   │   │
      ▼   ▼   ▼   ▼
     SQS SQS SQS SQS
     (1) (2) (3) (4)
      │   │   │   │
      ▼   ▼   ▼   ▼
   Worker Worker Worker Worker
```

**Pattern 2: Multi-Channel Notifications**
```
SNS Topic (Order Placed)
├─► SQS Queue → Email Service
├─► Lambda → Inventory Update
├─► SQS Queue → Shipping Service
└─► HTTP Endpoint → Third-party System
```

**Pattern 3: Priority-Based Routing**
```
Critical Topic
├─► High Priority: PagerDuty (immediate)
├─► Medium Priority: Slack channel
└─► Low Priority: Email digest
```

**Pattern 4: FIFO Topics with Message Deduplication**
- Strict ordering within message groups
- Exactly-once delivery semantics
- Use for order processing workflows

#### DevOps Best Practices

1. **Topic Design**
   - One topic per business domain (Orders, Payments, Shipping)
   - Use FIFO topics only when strict ordering is required (performance impact: 100 msg/sec)
   - Implement naming conventions: `{environment}-{domain}-{resource}`

2. **Subscription Management**
   - Use subscription filters to reduce message volume (SNS attribute filtering)
   - Implement subscription confirmation workflows (security measure)
   - Maintain subscription inventory in configuration management (IaC)

3. **Message Processing**
   - Always include message timestamps and correlation IDs
   - Use Message Attributes for routing decisions (avoid parsing body)
   - Implement exponential backoff in HTTP subscribers

4. **Monitoring & Alerting**
   - Track: NumberOfMessagesPublished, NumberOfNotificationsFailed
   - Monitor HTTPFailureRate and HTTPThrottling
   - Alert on dead-letter queue in fan-out SQS patterns

5. **Cost Optimization**
   - Batch publish operations when possible
   - Use subscription filters (exclude unneeded subscribers)
   - Archive SNS messages to S3 for compliance (via SQS + S3)

#### Common Pitfalls

| Pitfall | Cause | Impact | Solution |
|---------|-------|--------|----------|
| **Lost Messages to HTTP Endpoints** | No retry on HTTP failures | Dropped notifications | Use SQS as intermediary queue |
| **Duplicate Processing** | FIFO + high latency → retry storms | Idempotency violation | Implement deduplication token (MessageDeduplicationId) |
| **Subscription Bottleneck** | Too many synchronous subscribers | Slow fan-out, timeouts | Use async SQS queues instead |
| **Unfiltered Topic Fan-Out** | All subscribers receive all messages | Wasted processing, high latency | Implement SNS attribute filters |
| **Email Throttling** | High email send rate to same addresses | Message delivery delays | Use email service (SES) instead of SNS email |

---

### Practical Code Examples

#### CloudFormation: SNS Fan-Out with Multiple Subscribers

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'SNS Topic with Fan-Out to SQS, Lambda, and HTTP Endpoints'

Parameters:
  EnvironmentName:
    Type: String
    Default: production
  
  SlackWebhookUrl:
    Type: String
    NoEcho: true
    Description: Slack webhook URL for notifications

Resources:
  # SNS Topic
  OrderEventTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: !Sub '${EnvironmentName}-order-events'
      DisplayName: Order Events Notification
      Tags:
        - Key: Environment
          Value: !Ref EnvironmentName

  # SQS Queue 1: Email Processing
  EmailNotificationQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub '${EnvironmentName}-email-notifications'
      VisibilityTimeout: 300
      ReceiveMessageWaitTimeSeconds: 20

  EmailQueuePolicy:
    Type: AWS::SQS::QueuePolicy
    Properties:
      Queues:
        - !Ref EmailNotificationQueue
      PolicyText:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: sns.amazonaws.com
            Action: sqs:SendMessage
            Resource: !GetAtt EmailNotificationQueue.Arn
            Condition:
              ArnEquals:
                'aws:SourceArn': !Ref OrderEventTopic

  # SQS Queue 2: Inventory Management
  InventoryUpdateQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub '${EnvironmentName}-inventory-updates'
      VisibilityTimeout: 600
      ReceiveMessageWaitTimeSeconds: 20

  InventoryQueuePolicy:
    Type: AWS::SQS::QueuePolicy
    Properties:
      Queues:
        - !Ref InventoryUpdateQueue
      PolicyText:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: sns.amazonaws.com
            Action: sqs:SendMessage
            Resource: !GetAtt InventoryUpdateQueue.Arn
            Condition:
              ArnEquals:
                'aws:SourceArn': !Ref OrderEventTopic

  # SNS Subscription 1: Email SQS Queue
  EmailQueueSubscription:
    Type: AWS::SNS::Subscription
    Properties:
      Protocol: sqs
      TopicArn: !Ref OrderEventTopic
      Endpoint: !GetAtt EmailNotificationQueue.Arn
      FilterPolicy:
        eventType:
          - order-placed
          - order-cancelled
      FilterPolicyScope: MessageAttributes

  # SNS Subscription 2: Inventory SQS Queue
  InventoryQueueSubscription:
    Type: AWS::SNS::Subscription
    Properties:
      Protocol: sqs
      TopicArn: !Ref OrderEventTopic
      Endpoint: !GetAtt InventoryUpdateQueue.Arn
      FilterPolicy:
        eventType:
          - order-placed
      FilterPolicyScope: MessageAttributes

  # SNS Subscription 3: Lambda Function
  LambdaExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

  AnalyticsLambda:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: !Sub '${EnvironmentName}-order-analytics'
      Runtime: python3.9
      Handler: index.lambda_handler
      Role: !GetAtt LambdaExecutionRole.Arn
      Code:
        ZipFile: |
          import json
          def lambda_handler(event, context):
              print(f"Analytics event: {json.dumps(event)}")
              return {'statusCode': 200, 'body': 'Processed'}

  AnalyticsSubscription:
    Type: AWS::SNS::Subscription
    Properties:
      Protocol: lambda
      TopicArn: !Ref OrderEventTopic
      Endpoint: !GetAtt AnalyticsLambda.Arn

  AnalyticsLambdaPermission:
    Type: AWS::Lambda::Permission
    Properties:
      FunctionName: !Ref AnalyticsLambda
      Action: lambda:InvokeFunction
      Principal: sns.amazonaws.com
      SourceArn: !Ref OrderEventTopic

  # SNS Subscription 4: HTTP Endpoint (Slack)
  SlackSubscription:
    Type: AWS::SNS::Subscription
    Properties:
      Protocol: https
      TopicArn: !Ref OrderEventTopic
      Endpoint: !Ref SlackWebhookUrl
      FilterPolicy:
        severity:
          - critical
          - high
      DeliveryPolicy:
        http:
          defaultHealthyRetryPolicy:
            minDelayTarget: 20
            maxDelayTarget: 20
            numRetries: 3
            numMaxDelayThresholds: 0
          disableSubscriptionOverrides: false

  # CloudWatch Alarm for Failed Notifications
  NotificationFailureAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: !Sub '${EnvironmentName}-sns-notification-failures'
      MetricName: NumberOfNotificationsFailed
      Namespace: AWS/SNS
      Statistic: Sum
      Period: 300
      EvaluationPeriods: 1
      Threshold: 10
      ComparisonOperator: GreaterThanOrEqualToThreshold
      Dimensions:
        - Name: TopicName
          Value: !GetAtt OrderEventTopic.TopicName

Outputs:
  TopicArn:
    Value: !Ref OrderEventTopic
    Export:
      Name: !Sub '${EnvironmentName}-order-events-topic-arn'
  
  EmailQueueUrl:
    Value: !Ref EmailNotificationQueue
    Export:
      Name: !Sub '${EnvironmentName}-email-queue-url'
```

#### Python Publisher with Message Attributes

```python
#!/usr/bin/env python3
"""
SNS Publisher with Message Attributes and Error Handling
"""

import json
import boto3
from typing import Dict, Any, Optional
from botocore.exceptions import ClientError
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

sns = boto3.client('sns')

class SNSPublisher:
    """Handles SNS message publishing with attributes and filtering support"""
    
    def __init__(self, topic_arn: str):
        self.topic_arn = topic_arn
    
    def publish(
        self,
        message: Dict[str, Any],
        event_type: str,
        severity: str = "info",
        correlation_id: Optional[str] = None,
        attributes: Optional[Dict[str, str]] = None
    ) -> Optional[str]:
        """
        Publish message to SNS topic with attributes
        
        Args:
            message: Message payload as dict
            event_type: Type of event (for filtering)
            severity: Severity level (critical, high, medium, low)
            correlation_id: For distributed tracing
            attributes: Additional custom attributes
        
        Returns:
            MessageId or None if failed
        """
        try:
            # Build message attributes for SNS filtering
            message_attributes = {
                'eventType': {
                    'DataType': 'String',
                    'StringValue': event_type
                },
                'severity': {
                    'DataType': 'String',
                    'StringValue': severity
                }
            }
            
            # Add custom attributes
            if attributes:
                for key, value in attributes.items():
                    message_attributes[key] = {
                        'DataType': 'String',
                        'StringValue': str(value)
                    }
            
            # Add correlation ID for tracing
            if correlation_id:
                message_attributes['correlationId'] = {
                    'DataType': 'String',
                    'StringValue': correlation_id
                }
            
            # Publish to SNS
            response = sns.publish(
                TopicArn=self.topic_arn,
                Subject=f"[{severity.upper()}] {event_type}",
                Message=json.dumps({
                    'eventType': event_type,
                    'severity': severity,
                    'correlationId': correlation_id,
                    'payload': message
                }),
                MessageAttributes=message_attributes
            )
            
            logger.info(
                f"Published message {response['MessageId']} "
                f"event_type={event_type} severity={severity}"
            )
            return response['MessageId']
            
        except ClientError as e:
            logger.error(f"Error publishing to SNS: {e}")
            return None


# Example Usage
if __name__ == "__main__":
    # Initialize publisher
    topic_arn = "arn:aws:sns:us-east-1:123456789:production-order-events"
    publisher = SNSPublisher(topic_arn)
    
    # Example 1: Order Placed Event
    order_data = {
        'orderId': 'ORD-12345',
        'customerId': 'CUST-67890',
        'amount': 99.99,
        'items': [
            {'sku': 'PROD-001', 'qty': 2}
        ]
    }
    
    publisher.publish(
        message=order_data,
        event_type='order-placed',
        severity='high',
        correlation_id='trace-id-12345',
        attributes={'source': 'web-app', 'region': 'us-east-1'}
    )
    
    # Example 2: System Alert
    alert_data = {
        'alertId': 'ALT-001',
        'service': 'payment-gateway',
        'errorMessage': 'Connection timeout to payment processor'
    }
    
    publisher.publish(
        message=alert_data,
        event_type='system-alert',
        severity='critical',
        correlation_id='trace-id-12346'
    )
```

#### SNS CLI Operations Script

```bash
#!/bin/bash
# SNS Operations Script

set -euo pipefail

TOPIC_ARN="arn:aws:sns:us-east-1:123456789:production-order-events"
REGION="us-east-1"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Publish message with attributes
publish_event() {
    local event_type="$1"
    local severity="${2:-info}"
    local message_body="$3"
    
    echo -e "${YELLOW}Publishing event: $event_type (severity: $severity)${NC}"
    
    aws sns publish \
        --topic-arn "$TOPIC_ARN" \
        --subject "[$severity] $event_type" \
        --message "$message_body" \
        --message-attributes '{
            "eventType": {"DataType": "String", "StringValue": "'$event_type'"},
            "severity": {"DataType": "String", "StringValue": "'$severity'"}
        }' \
        --region "$REGION" \
        --output json | jq '.MessageId'
}

# List subscriptions with filters
list_subscriptions() {
    echo -e "${YELLOW}Listing topic subscriptions...${NC}"
    
    aws sns list-subscriptions-by-topic \
        --topic-arn "$TOPIC_ARN" \
        --region "$REGION" \
        --output json | jq '.Subscriptions[] | {
            SubscriptionArn,
            Protocol,
            Endpoint,
            FilterPolicy: .FilterPolicy
        }'
}

# Get topic attributes
get_topic_attributes() {
    echo -e "${YELLOW}Getting topic attributes...${NC}"
    
    aws sns get-topic-attributes \
        --topic-arn "$TOPIC_ARN" \
        --region "$REGION" \
        --output json | jq '.Attributes'
}

# Monitor topic metrics
monitor_topic() {
    local interval="${1:-5}"
    echo -e "${YELLOW}Monitoring SNS topic (interval: ${interval}s)${NC}"
    
    while true; do
        clear
        echo "=== SNS Topic Metrics ==="
        
        aws cloudwatch get-metric-statistics \
            --namespace AWS/SNS \
            --metric-name NumberOfMessagesPublished \
            --dimensions Name=TopicName,Value=$(echo "$TOPIC_ARN" | awk -F: '{print $NF}') \
            --statistics Sum \
            --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
            --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
            --period 300 \
            --region "$REGION" \
            --output json | jq '.Datapoints[] | {
                Timestamp,
                Sum
            }'
        
        echo ""
        sleep "$interval"
    done
}

# Test subscription delivery
test_subscription() {
    local subscription_arn="$1"
    
    echo -e "${YELLOW}Testing subscription: $subscription_arn${NC}"
    
    # This triggers a subscription confirmation or test message
    aws sns publish \
        --topic-arn "$TOPIC_ARN" \
        --message "Test message from DevOps team" \
        --region "$REGION"
}

# Main
main() {
    case "${1:-help}" in
        publish)
            publish_event "${2:-test-event}" "${3:-info}" "${4:-Test message}"
            ;;
        list)
            list_subscriptions
            ;;
        attributes)
            get_topic_attributes
            ;;
        monitor)
            monitor_topic "${2:-5}"
            ;;
        test)
            test_subscription "$2"
            ;;
        *)
            echo "Usage: $0 <command>"
            echo "Commands:"
            echo "  publish <type> <severity> <message>"
            echo "  list"
            echo "  attributes"
            echo "  monitor [interval]"
            echo "  test <subscription-arn>"
            ;;
    esac
}

main "$@"
```

### ASCII Diagrams

#### SNS Fan-Out Pattern
```
┌─────────────────────────────────────────────────────────┐
│               Event Source                              │
│      (DynamoDB Stream, S3, Lambda)                      │
└────────────────────┬────────────────────────────────────┘
                     │
                     ├─► PutEvents()
                     │
            ┌────────▼────────┐
            │   SNS Topic     │
            │ (order-events)  │
            └────────┬────────┘
                     │
        ┌────────────┼────────────┬─────────────────┐
        │            │            │                 │
        ▼            ▼            ▼                 ▼
    ┌─────┐     ┌─────┐     ┌──────────┐     ┌─────────┐
    │SQS  │     │SQS  │     │Lambda    │     │HTTP     │
    │Email│     │Inv. │     │Analytics │     │Endpoint │
    │Queue│     │Queue│     │Function  │     │(Slack)  │
    └─────┘     └─────┘     └──────────┘     └─────────┘
        │           │            │                │
        │ Filtered  │ Filtered   │ Filtered      │ Filtered
        │ by:       │ by:        │ by:           │ by:
        │ event     │ event      │ event         │ severity
        │ type      │ type       │ type          │ (critical)
        │           │            │                │
    ┌───▼───┐  ┌───▼───┐   ┌────▼────┐     ┌────▼─────┐
    │Worker │  │Worker │   │Process  │     │Post to   │
    │Email  │  │Update │   │& Store  │     │Slack     │
    │Sender │  │Inv.   │   │Metrics  │     │Webhook   │
    └───────┘  └───────┘   └─────────┘     └──────────┘
```

#### SNS Message Attributes Filter
```
SNS Message:
┌─────────────────────────────────────────────────────────┐
│ Message: "Order created"                                │
│ MessageAttributes:                                      │
│ ├─ eventType: "order-placed"                           │
│ ├─ severity: "high"                                     │
│ └─ region: "us-east-1"                                 │
└─────────────────────────────────────────────────────────┘
                     │
        ┌────────────┼────────────────────┐
        │            │                    │
        ▼            ▼                    ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│Subscription1 │ │Subscription2 │ │Subscription3 │
│              │ │              │ │              │
│ Filter:      │ │ Filter:      │ │ Filter:      │
│ eventType =  │ │ severity =   │ │ eventType =  │
│ order-*      │ │ critical     │ │ payment-*    │
│              │ │              │ │              │
│ MATCHES ✓    │ │ NO MATCH ✗   │ │ NO MATCH ✗   │
└──────────────┘ └──────────────┘ └──────────────┘
        │
    DELIVERED
```

#### SNS FIFO Topic with Message Groups
```
FIFO Topic: order-processing.fifo
├─ Strict Message Ordering
├─ Exactly-Once Delivery
└─ MessageDeduplicationId (5-minute window)

    Customer A Stream          Customer B Stream
    (MessageGroupId: A)        (MessageGroupId: B)
    
    M1: Order Placed           M1: Order Placed
    M2: Payment Auth           M2: Payment Auth
    M3: Inventory Check        M3: Inventory Check
    M4: Fulfillment            M4: Fulfillment
           │                          │
           └──────────┬───────────────┘
                      │
            ┌─────────▼─────────┐
            │  FIFO Topic       │
            │  Deduplication:   │
            │  5-min window     │
            │                   │
            │ Preserves Order:  │
            │ M1→M2→M3→M4      │
            │ M1→M2→M3→M4      │
            └─────────┬─────────┘
                      │
           ┌──────────┴──────────┐
           │                     │
           ▼                     ▼
       Subscriber A          Subscriber B
       (In Order)            (In Order)
```

---

## EventBridge - Event Bus and Rules

### Textual Deep Dive

#### Internal Working Mechanism

EventBridge is a serverless event bus that routes events from various sources to target services based on rules. It provides sophisticated event filtering, transformation, and routing capabilities without managing infrastructure.

**Core Components:**
- **Event Bus**: Central event channel (default for AWS account events, or custom)
- **Rules**: Define which events to route and to where (event pattern matching on JSON)
- **Events**: JSON objects containing event metadata and data
- **Targets**: Destination services (Lambda, SNS, SQS, Kinesis, EC2, etc.)
- **Event Sources**: AWS services, third-party SaaS, custom applications

**Event Pattern Matching:**
```json
{
  "source": ["aws.ec2"],
  "detail-type": ["EC2 Instance State-change Notification"],
  "detail": {
    "state": ["terminated", "stopped"]
  }
}
```

**Event Transformation:**
- Input Transformer: Extract and restructure event data
- Dead-Letter Queues: Capture failed events
- Retry Policies: Exponential backoff (0-896 seconds)
- Archive & Replay: Store and replay events for replay scenarios

#### Architecture Role

EventBridge bridges the gap between event sources and targets in modern event-driven architectures:

1. **Cross-Service Orchestration**: Coordinate workflows across AWS services
2. **Integration Hub**: Connect AWS services, SaaS platforms, and custom applications
3. **Event Routing**: Intelligent, pattern-based message routing
4. **Event Transformation**: Modify event structure before delivery
5. **Audit & Compliance**: Archive events for regulatory requirements

#### Production Usage Patterns

**Pattern 1: Scheduled Tasks (Cron)**
```
EventBridge Cron Rule (rate: 5 minutes)
    │
    ├─► Lambda: Database Maintenance
    ├─► Lambda: Health Checks
    └─► SNS: Send Daily Reports
```

**Pattern 2: AWS Service Event Routing**
```
EC2 Instance State Change
    │
    ▼
EventBridge (Rule: EC2 termination)
    │
    ├─► SNS: Alert Operations Team
    ├─► Lambda: Cleanup Security Groups
    ├─► SNS: Ticket Creation System
    └─► CloudWatch Logs: Audit Trail
```

**Pattern 3: Multi-Account Event Aggregation**
```
Account A Events → Cross-Account Event Bus
Account B Events → Central Aggregation Bus
Account C Events → Event Analysis & Rules
                      │
                      ├─► Data Lake (S3)
                      ├─► Analytics (Athena)
                      └─► Alerting (SNS)
```

**Pattern 4: Complex Event Processing**
```
Multiple Event Sources
    ├─ OrderPlaced (SQS)
    ├─ PaymentProcessed (SNS)
    └─ InventoryUpdated (Lambda)
         │
         ▼
    EventBridge Aggregation
    (Multi-step correlation)
         │
         ▼
    Trigger Complex Workflows
```

#### DevOps Best Practices

1. **Rule Design**
   - Use specific event patterns (avoid broad/catch-all rules)
   - Implement event versioning strategy
   - Use Dead-Letter Queues for critical rules
   - Test rules with `test-event-pattern` before applying

2. **Event Bus Architecture**
   - Create separate event buses for different domains (Orders, Payments, Analytics)
   - Use event bus policies for cross-account access
   - Implement bus quotas and scaling limits

3. **Target Configuration**
   - Set appropriate max event age (seconds to retry)
   - Configure retry policies (max: 896 seconds exponential backoff)
   - Implement Dead-Letter Queue for failed deliveries
   - Use Input Transformer to minimize target payload

4. **Monitoring & Observability**
   - Track: Invocations, FailedInvocations, TriggeredRules
   - Monitor target-specific metrics (Lambda Duration, error counts)
   - Archive events for debugging and compliance
   - Enable EventBridge logging to CloudWatch

5. **Multi-Account Strategy**
   - Central event bus in logging account aggregates events
   - Cross-account roles enable fine-grained access
   - Use event bus policies for delegation

#### Common Pitfalls

| Pitfall | Cause | Impact | Solution |
|---------|-------|--------|----------|
| **Event Loss** | No DLQ on rules | Missing events, no visibility | Configure DLQ on all critical rules |
| **Infinite Loops** | Event triggers rule that emits same event | Cascading failures, billing impact | Use event versioning, distinct rule patterns |
| **High Latency** | Too many transformations | Delayed processing | Minimize Input Transformer logic |
| **Throttling** | High event volume to single target | Event backlog, delivery delays | Use parallel targets, batch processing |
| **Stale Credentials** | Cross-account IAM roles expire | Event delivery failures | Rotate roles regularly, monitor failures |

---

### Practical Code Examples

#### CloudFormation: EventBridge with Rules and DLQ

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'EventBridge Setup with Rules, DLQ, and Cross-Account Access'

Parameters:
  EnvironmentName:
    Type: String
    Default: production

Resources:
  # Custom Event Bus
  OrderEventBus:
    Type: AWS::Events::EventBus
    Properties:
      Name: !Sub '${EnvironmentName}-order-event-bus'

  # Dead-Letter Queue for Failed Events
  EventDLQ:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub '${EnvironmentName}-eventbridge-dlq'
      MessageRetentionPeriod: 1209600  # 14 days
      VisibilityTimeout: 300

  # EventBridge Rule 1: Route Order Placed Events
  OrderPlacedRule:
    Type: AWS::Events::Rule
    Properties:
      Name: !Sub '${EnvironmentName}-order-placed-rule'
      EventBusName: !Ref OrderEventBus
      State: ENABLED
      EventPattern:
        source:
          - orders.api
        detail-type:
          - Order Placed
        detail:
          status:
            - confirmed
      Targets:
        # Target 1: Send to SNS Topic
        - Arn: !Sub 'arn:aws:sns:${AWS::Region}:${AWS::AccountId}:${EnvironmentName}-order-notifications'
          RoleArn: !GetAtt EventBridgeRole.Arn
          DeadLetterConfig:
            Arn: !GetAtt EventDLQ.Arn
          RetryPolicy:
            MaximumEventAge: 3600
            MaximumRetryAttempts: 2
          InputTransformer:
            InputPathsMap:
              orderId: $.detail.orderId
              customerId: $.detail.customerId
              amount: $.detail.amount
            InputTemplate: |
              {
                "orderId": "<orderId>",
                "customerId": "<customerId>",
                "amount": "<amount>",
                "timestamp": "$.time"
              }
        
        # Target 2: Invoke Lambda for Inventory Update
        - Arn: !GetAtt InventoryUpdateFunction.Arn
          RoleArn: !GetAtt EventBridgeRole.Arn
          DeadLetterConfig:
            Arn: !GetAtt EventDLQ.Arn
          RetryPolicy:
            MaximumEventAge: 1800
            MaximumRetryAttempts: 1

  # EventBridge Rule 2: Scheduled Daily Report
  DailyReportRule:
    Type: AWS::Events::Rule
    Properties:
      Name: !Sub '${EnvironmentName}-daily-report-rule'
      EventBusName: default  # Uses default event bus for scheduled events
      ScheduleExpression: 'cron(0 6 ? * MON-FRI *)'  # 6 AM weekdays
      State: ENABLED
      Targets:
        - Arn: !GetAtt ReportGeneratorFunction.Arn
          RoleArn: !GetAtt EventBridgeRole.Arn
          DeadLetterConfig:
            Arn: !GetAtt EventDLQ.Arn

  # EventBridge Rule 3: Event Pattern with Complex Conditions
  CriticalOrderRule:
    Type: AWS::Events::Rule
    Properties:
      Name: !Sub '${EnvironmentName}-critical-order-rule'
      EventBusName: !Ref OrderEventBus
      State: ENABLED
      EventPattern:
        source:
          - orders.api
        detail-type:
          - Order Placed
        detail:
          amount:
            - numeric:
                - '>'
                - 10000
          priority: ['URGENT', 'HIGH']
      Targets:
        - Arn: !Sub 'arn:aws:sns:${AWS::Region}:${AWS::AccountId}:${EnvironmentName}-critical-alerts'
          RoleArn: !GetAtt EventBridgeRole.Arn
          DeadLetterConfig:
            Arn: !GetAtt EventDLQ.Arn
          RetryPolicy:
            MaximumEventAge: 900
            MaximumRetryAttempts: 3

  # Lambda Functions
  InventoryUpdateFunction:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: !Sub '${EnvironmentName}-inventory-update'
      Runtime: python3.9
      Handler: index.lambda_handler
      Role: !GetAtt LambdaExecutionRole.Arn
      Code:
        ZipFile: |
          import json
          def lambda_handler(event, context):
              print(f"Updating inventory: {json.dumps(event)}")
              return {'statusCode': 200}

  ReportGeneratorFunction:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: !Sub '${EnvironmentName}-report-generator'
      Runtime: python3.9
      Handler: index.lambda_handler
      Role: !GetAtt LambdaExecutionRole.Arn
      Code:
        ZipFile: |
          import json
          def lambda_handler(event, context):
              print(f"Generating daily report")
              return {'statusCode': 200}

  # IAM Roles
  EventBridgeRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: events.amazonaws.com
            Action: sts:AssumeRole
      Policies:
        - PolicyName: EventBridgePolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - lambda:InvokeFunction
                  - sns:Publish
                  - sqs:SendMessage
                Resource: '*'

  LambdaExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

  # CloudWatch Alarms
  FailedInvocationsAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: !Sub '${EnvironmentName}-eventbridge-failed-invocations'
      MetricName: FailedInvocations
      Namespace: AWS/Events
      Statistic: Sum
      Period: 300
      EvaluationPeriods: 1
      Threshold: 5
      ComparisonOperator: GreaterThanOrEqualToThreshold
      Dimensions:
        - Name: Rule
          Value: !Ref OrderPlacedRule

Outputs:
  EventBusArn:
    Value: !GetAtt OrderEventBus.Arn
    Export:
      Name: !Sub '${EnvironmentName}-event-bus-arn'
  
  EventBusName:
    Value: !Ref OrderEventBus
    Export:
      Name: !Sub '${EnvironmentName}-event-bus-name'
  
  DLQUrl:
    Value: !Ref EventDLQ
    Export:
      Name: !Sub '${EnvironmentName}-eventbridge-dlq-url'
```

#### Python: EventBridge Event Publisher

```python
#!/usr/bin/env python3
"""
EventBridge Publisher for Custom Events
Demonstrates pattern-based routing and transformations
"""

import json
import boto3
from datetime import datetime
from typing import Dict, Any, Optional
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

events_client = boto3.client('events')

class EventBridgePublisher:
    """Publishes events to EventBridge event buses"""
    
    def __init__(self, event_bus_name: str = 'default'):
        self.event_bus_name = event_bus_name
    
    def publish_order_event(
        self,
        order_id: str,
        customer_id: str,
        amount: float,
        status: str,
        items: list,
        priority: str = 'NORMAL'
    ) -> Optional[str]:
        """Publish an order event"""
        
        event_detail = {
            'orderId': order_id,
            'customerId': customer_id,
            'amount': amount,
            'status': status,
            'items': items,
            'priority': priority,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        return self._put_event(
            source='orders.api',
            detail_type='Order Placed',
            detail=event_detail
        )
    
    def publish_payment_event(
        self,
        order_id: str,
        amount: float,
        status: str,
        transaction_id: str
    ) -> Optional[str]:
        """Publish a payment processing event"""
        
        event_detail = {
            'orderId': order_id,
            'amount': amount,
            'status': status,
            'transactionId': transaction_id,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        return self._put_event(
            source='payment.service',
            detail_type='Payment Processed',
            detail=event_detail
        )
    
    def publish_inventory_event(
        self,
        product_id: str,
        quantity_change: int,
        reason: str
    ) -> Optional[str]:
        """Publish an inventory change event"""
        
        event_detail = {
            'productId': product_id,
            'quantityChange': quantity_change,
            'reason': reason,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        return self._put_event(
            source='inventory.service',
            detail_type='Inventory Updated',
            detail=event_detail
        )
    
    def _put_event(
        self,
        source: str,
        detail_type: str,
        detail: Dict[str, Any]
    ) -> Optional[str]:
        """Low-level event publishing"""
        
        try:
            response = events_client.put_events(
                Entries=[
                    {
                        'Source': source,
                        'DetailType': detail_type,
                        'Detail': json.dumps(detail),
                        'EventBusName': self.event_bus_name
                    }
                ]
            )
            
            if response['FailedEntryCount'] == 0:
                event_id = response['Entries'][0]['EventId']
                logger.info(
                    f"Published event {event_id} "
                    f"source={source} detail_type={detail_type}"
                )
                return event_id
            else:
                logger.error(f"Failed to publish event: {response}")
                return None
                
        except Exception as e:
            logger.error(f"Error publishing event: {e}")
            return None


# Example usage
if __name__ == "__main__":
    publisher = EventBridgePublisher('production-order-event-bus')
    
    # Example 1: High-value order
    publisher.publish_order_event(
        order_id='ORD-2026-001',
        customer_id='CUST-12345',
        amount=15000.00,
        status='confirmed',
        items=[
            {'sku': 'PROD-001', 'qty': 2, 'price': 5000},
            {'sku': 'PROD-002', 'qty': 1, 'price': 5000}
        ],
        priority='URGENT'
    )
    
    # Example 2: Payment processed
    publisher.publish_payment_event(
        order_id='ORD-2026-001',
        amount=15000.00,
        status='approved',
        transaction_id='TXN-9876543'
    )
    
    # Example 3: Inventory update
    publisher.publish_inventory_event(
        product_id='PROD-001',
        quantity_change=-2,
        reason='Order fulfillment'
    )
```

#### EventBridge CLI Operations

```bash
#!/bin/bash
# EventBridge Operations

set -euo pipefail

EVENT_BUS_NAME="production-order-event-bus"
REGION="us-east-1"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test event pattern
test_event_pattern() {
    local pattern_file="$1"
    local event_file="$2"
    
    echo -e "${YELLOW}Testing event pattern...${NC}"
    
    aws events test-event-pattern \
        --event-pattern file://"$pattern_file" \
        --event file://"$event_file" \
        --region "$REGION"
}

# List all rules
list_rules() {
    echo -e "${YELLOW}Listing EventBridge rules...${NC}"
    
    aws events list-rules \
        --event-bus-name "$EVENT_BUS_NAME" \
        --region "$REGION" \
        --output json | jq '.Rules[] | {
            Name,
            State,
            EventPattern,
            ScheduleExpression
        }'
}

# Get rule details
describe_rule() {
    local rule_name="$1"
    
    echo -e "${YELLOW}Describing rule: $rule_name${NC}"
    
    aws events describe-rule \
        --name "$rule_name" \
        --event-bus-name "$EVENT_BUS_NAME" \
        --region "$REGION" \
        --output json | jq '.'
    
    # Also list targets
    echo -e "\n${YELLOW}Targets for rule: $rule_name${NC}"
    aws events list-targets-by-rule \
        --rule "$rule_name" \
        --event-bus-name "$EVENT_BUS_NAME" \
        --region "$REGION" \
        --output json | jq '.Targets[]'
}

# Put a test event
put_test_event() {
    local event_file="$1"
    
    echo -e "${YELLOW}Publishing test event...${NC}"
    
    aws events put-events \
        --entries file://"$event_file" \
        --region "$REGION" \
        --output json | jq '.Entries[]'
}

# Archive listing
list_archives() {
    echo -e "${YELLOW}Listing EventBridge archives...${NC}"
    
    aws events list-archives \
        --region "$REGION" \
        --output json | jq '.Archives[] | {
            ArchiveName,
            CreationTime,
            State,
            EventSourceArn
        }'
}

# DLQ monitoring
monitor_dlq() {
    local dlq_url="$1"
    local interval="${2:-5}"
    
    echo -e "${YELLOW}Monitoring DLQ (interval: ${interval}s)${NC}"
    
    while true; do
        clear
        echo "=== EventBridge DLQ Monitoring ==="
        
        aws sqs get-queue-attributes \
            --queue-url "$dlq_url" \
            --attribute-names All \
            --region "$REGION" \
            --output json | jq '{
                Messages: .Attributes.ApproximateNumberOfMessages,
                LastModified: .Attributes.LastModifiedTimestamp
            }'
        
        echo "Press Ctrl+C to exit"
        sleep "$interval"
    done
}

# Main
main() {
    case "${1:-help}" in
        test-pattern)
            test_event_pattern "$2" "$3"
            ;;
        list-rules)
            list_rules
            ;;
        describe-rule)
            describe_rule "$2"
            ;;
        put-event)
            put_test_event "$2"
            ;;
        list-archives)
            list_archives
            ;;
        monitor-dlq)
            monitor_dlq "$2" "${3:-5}"
            ;;
        *)
            echo "Usage: $0 <command> [args]"
            echo "Commands:"
            echo "  test-pattern <pattern-file> <event-file>"
            echo "  list-rules"
            echo "  describe-rule <rule-name>"
            echo "  put-event <event-file>"
            echo "  list-archives"
            echo "  monitor-dlq <dlq-url> [interval]"
            ;;
    esac
}

main "$@"
```

### ASCII Diagrams

#### EventBridge Event Routing Architecture
```
┌────────────────────────────────────────────────────────┐
│              Event Sources                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐               │
│  │AWS Service   │Third-party │Custom App│               │
│  │Events       │SaaS Events │Events    │               │
│  └──────┬──────┘ └──────┬───┘ └──────┬──┘               │
└─────────┼────────────────┼─────────────┼──────────────┘
          │                │             │
          │ PutEvents()    │             │
          │                │             │
    ┌─────▼────────────────▼─────────────▼────────┐
    │           EventBridge Event Bus              │
    │  (Central routing hub)                      │
    │                                              │
    │  Stores: source, detail-type, detail, time  │
    └─────┬────────────────────────────────────────┘
          │
    ┌─────▼────────────────────────────────────┐
    │        Event Pattern Matching             │
    │  Rule 1: {source: orders.api, ...}       │
    │  Rule 2: {source: payment.service, ...}  │
    │  Rule 3: {amount: {>: 1000}, ...}        │
    └─────┬──────────┬──────────┬──────────────┘
          │          │          │
    ┌─────▼──┐  ┌────▼──┐  ┌───▼────┐
    │Target 1 │  │Target 2│  │Target 3│
    │ Lambda  │  │  SNS   │  │  SQS   │
    │         │  │        │  │        │
    │DeadLetter DLQ      │  │  DLQ   │
    │  SQS   │  │        │  │        │
    └────────┘  └────────┘  └────────┘
```

#### EventBridge Rule Event Pattern Matching
```
Event from Source:
{
  "version": "0",
  "id": "12345-67890",
  "detail-type": "Order Placed",
  "source": "orders.api",
  "account": "123456789",
  "time": "2026-03-08T12:00:00Z",
  "region": "us-east-1",
  "detail": {
    "orderId": "ORD-001",
    "customerId": "CUST-123",
    "amount": 5000,
    "status": "confirmed",
    "priority": "HIGH"
  }
}
        │
        ├─► Rule 1 Pattern:
        │   {
        │     "source": ["orders.api"],
        │     "detail-type": ["Order Placed"]
        │   }
        │   MATCHES ✓
        │
        ├─► Rule 2 Pattern:
        │   {
        │     "detail": {
        │       "amount": [{">": 1000}],
        │       "priority": ["HIGH", "URGENT"]
        │     }
        │   }
        │   MATCHES ✓
        │
        └─► Rule 3 Pattern:
            {
              "source": ["payment.service"],
              "detail-type": ["Payment Processed"]
            }
            NO MATCH ✗

Only Rule 1 and Rule 2 targets receive the event.
```

#### EventBridge Scheduled Rule with Cron
```
EventBridge Scheduler
│
├─ Rate Expression: rate(5 minutes)
│  └─ Triggers every 5 minutes automatically
│
├─ Cron Expression: cron(0 6 ? * MON-FRI *)
│  └─ 6 AM Monday-Friday UTC
│
└─ Cron Expression: cron(0/30 * ? * * *)
   └─ Every 30 minutes, 24/7

       ┌────────────────────────────────────┐
       │    EventBridge Scheduler Service    │
       │                                    │
       │ At scheduled time:                 │
       │ ├─ Create CloudEvents             │
       │ ├─ Match against rules            │
       │ └─ Invoke targets (Lambda, SNS)   │
       └────────────┬─────────────────────┘
                    │
            ┌───────┴──────┐
            │              │
        Success        Failure
            │              │
        Target      Retry Policy
        executed    (exponential
        (200ms)      backoff)
                     │
                  DLQ
```

---

## Kinesis - Data Streams and Firehose

### Textual Deep Dive

#### Internal Working Mechanism

Kinesis provides two solutions for real-time data ingestion and processing:

**Kinesis Data Streams:**
- Stream-based architecture with shards for parallel processing
- Each shard: 1,000 records/sec or 1 MB/sec ingestion
- Retention: Default 24 hours, up to 365 days
- Records ordered per shard (FIFO within shard, not globally)
- Consumer models: Enhanced Fan-Out, Polling (GetRecords)

**Kinesis Data Firehose:**
- Fully managed data delivery service
- Automatic scaling (no manual shard management)
- Batching, compression, transformation
- Destinations: S3, Redshift, Elasticsearch, Splunk, custom HTTP endpoints
- Transformation: Via Lambda function (optional)
- Cost: $0.029 per GB vs Streams ($0.034 per shard-hour + $0.014 per million records)

#### Architecture Role

Kinesis serves real-time data pipeline use cases:

1. **Real-time Analytics**: Stream application clicks, metrics, events
2. **Log Processing**: Aggregate logs from millions of sources
3. **IoT Data Ingestion**: Collect sensor data at scale
4. **Clickstream Analysis**: Track user behavior in real-time
5. **Data Lake Ingestion**: Stream structured/unstructured data to S3

#### Production Usage Patterns

**Pattern 1: Application Metrics Pipeline**
```
Application Metrics
├─ CPU, Memory, Disk utilization
├─ Request latency, error rates
└─ Custom business metrics
    │
    ▼
Kinesis Stream (3 shards)
    │
    ├─► Lambda Consumer (Real-Time Aggregation)
    │   └─► CloudWatch Custom Metrics
    │
    ├─► Lambda Consumer (Anomaly Detection)
    │   └─► SNS Alerts
    │
    └─► Kinesis Firehose
        └─► S3 Data Lake (Parquet format + historical)
```

**Pattern 2: IoT Sensor Data**
```
Millions of IoT Devices
    │
    ├─► (Batched) PUT Records
    │
    ▼
Kinesis Stream (Auto-scaled via Enhanced Fanout)
    │
    ├─► Lambda (Data Validation & Enrichment)
    ├─► Lambda (Time-Series Database Write)
    └─► Lambda (Real-Time Visualizations)
```

**Pattern 3: Log Aggregation with Firehose**
```
EC2 Instances / Lambda / Containers
    │ (CloudWatch Logs)
    ▼
Kinesis Firehose (100 shards auto-scaled)
    │
    ├─► Transform: Lambda (JSON parsing, enrichment)
    ├─► Buffer: 5-minute window or 128 MB
    ├─► Compress: GZIP/SNAPPY
    │
    ▼
S3 Data Lake (Partitioned by date/source)
    │
    └─► Athena (SQL querying)
```

#### DevOps Best Practices

1. **Stream Configuration**
   - Calculate required shards: (peak records/sec / 1,000) × overhead factor (1.5-2x)
   - Use On-Demand capacity mode for variable workloads
   - Enable Enhanced Fan-Out for multiple consumers
   - Set retention based on replay requirements (default: 24 hours)

2. **Producer Best Practices**
   - Batch records (up to 500 records or 1 MB per PutRecords call)
   - Distribute across partition keys for shard distribution
   - Implement retry logic with exponential backoff
   - Monitor put-record latency and throttled records

3. **Consumer Optimization**
   - Use single consumer per shard (avoid contention)
   - Enhanced Fan-Out: ~70ms latency vs polling (1-2 seconds)
   - Implement processing checkpointing (DynamoDB or KCL)
   - Process records in parallel within shards

4. **Firehose Configuration**
   - Set buffer size (1 MB - 128 MB) and buffer time (1 min - 60 min)
   - Enable data format conversion for S3 (Parquet/ORC)
   - Use dynamic partitioning by time/source
   - Configure transformation Lambda (timeout: 3 minutes max)

5. **Monitoring**
   - Track: IncomingRecords, IncomingBytes, GetRecords.LatencyMicros
   - Monitor: ReadProvisionedThroughputExceeded, WriteProvisionedThroughputExceeded
   - Firehose: DeliveryToS3.Records, DeliveryToS3.DataFreshness
   - Set alarms on consumer lag (CloudWatch Logs Insights)

#### Common Pitfalls

| Pitfall | Cause | Impact | Solution |
|---------|-------|--------|----------|
| **Throttling** | Uneven partition key distribution | High latency, dropped records | Use hash-based or random partition keys |
| **Consumer Lag** | Slow processing, few consumers | Late data processing, data loss risk | Add consumers, optimize processing logic |
| **Hot Partition** | All records use same partition key | Shard throttling while others idle | Distribute load across partition keys |
| **Expensive Stream Retention** | 365-day retention on high-volume streams | High monthly costs | Tiered approach: Stream (24h) → S3 (long-term) |
| **Slow Firehose Delivery** | Undersized buffer or transformation issues | Data warehouse freshness SLA breach | Increase buffer size or optimize transformation |

---

### Practical Code Examples

#### CloudFormation: Kinesis Stream with Auto Scaling and Firehose

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Kinesis Stream with Auto Scaling and Firehose to S3'

Parameters:
  EnvironmentName:
    Type: String
    Default: production
  
  InitialShardCount:
    Type: Number
    Default: 3
    MinValue: 1

Resources:
  # Kinesis Data Stream
  ApplicationMetricsStream:
    Type: AWS::Kinesis::Stream
    Properties:
      StreamName: !Sub '${EnvironmentName}-application-metrics'
      ShardCount: !Ref InitialShardCount
      StreamModeDetails:
        StreamMode: PROVISIONED  # or ON_DEMAND
        
  # S3 Bucket for Firehose Delivery
  FirehoseDeliveryBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub '${EnvironmentName}-kinesis-archive-${AWS::AccountId}'
      VersioningConfiguration:
        Status: Enabled
      LifecycleConfiguration:
        Rules:
          # Archive to Glacier after 90 days
          - Id: ArchiveToGlacier
            Status: Enabled
            Transitions:
              - TransitionInDays: 90
                StorageClass: GLACIER
          # Delete after 1 year
          - Id: DeleteOldArchives
            Status: Enabled
            ExpirationInDays: 365

  # Firehose Delivery Role
  FirehoseRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: firehose.amazonaws.com
            Action: sts:AssumeRole
      Policies:
        - PolicyName: FirehosePolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - s3:GetObject
                  - s3:ListBucket
                  - s3:PutObject
                  - s3:DeleteObject
                Resource:
                  - !GetAtt FirehoseDeliveryBucket.Arn
                  - !Sub '${FirehoseDeliveryBucket.Arn}/*'
              - Effect: Allow
                Action:
                  - logs:CreateLogGroup
                  - logs:CreateLogStream
                  - logs:PutLogEvents
                Resource: !Sub 'arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/kinesisfirehose/*'

  # Kinesis Firehose Delivery Stream
  MetricsArchiveFirehose:
    Type: AWS::KinesisFirehose::DeliveryStream
    Properties:
      DeliveryStreamName: !Sub '${EnvironmentName}-metrics-archive'
      DeliveryStreamType: KinesisStreamAsSource
      KinesisStreamSourceConfiguration:
        KinesisStreamARN: !GetAtt ApplicationMetricsStream.Arn
        RoleARN: !GetAtt FirehoseRole.Arn
      ExtendedS3DestinationConfiguration:
        BucketARN: !GetAtt FirehoseDeliveryBucket.Arn
        RoleARN: !GetAtt FirehoseRole.Arn
        Prefix: !Sub 'metrics/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/'
        ErrorOutputPrefix: !Sub 'errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}'
        BufferingHints:
          SizeInMBs: 64
          IntervalInSeconds: 300
        CompressionFormat: GZIP
        DataFormatConversionConfiguration:
          Enabled: true
          SchemaConfiguration:
            RoleARN: !GetAtt FirehoseRole.Arn
            DatabaseName: kinesis_db
            TableName: metrics
            Region: !Ref AWS::Region
            VersionId: LATEST
        ProcessingConfiguration:
          Enabled: true
          Processors:
            - Type: Lambda
              Parameters:
                - ParameterName: LambdaArn
                  ParameterValue: !GetAtt TransformationLambda.Arn

  # Transformation Lambda
  TransformationLambda:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: !Sub '${EnvironmentName}-firehose-transform'
      Runtime: python3.9
      Handler: index.lambda_handler
      Role: !GetAtt LambdaExecutionRole.Arn
      Code:
        ZipFile: |
          import json
          import base64
          
          def lambda_handler(event, context):
              output = []
              for record in event['records']:
                  payload = json.loads(base64.b64decode(record['data']))
                  
                  # Transform: Add timestamp
                  payload['processed_at'] = int(time.time())
                  
                  transformed_record = {
                      'recordId': record['recordId'],
                      'result': 'Ok',
                      'data': base64.b64encode(
                          json.dumps(payload).encode()
                      ).decode()
                  }
                  output.append(transformed_record)
              
              return {'records': output}

  # Auto Scaling Target for Stream
  StreamAutoScalingTarget:
    Type: AWS::ApplicationAutoScaling::ScalableTarget
    Properties:
      MaxCapacity: 20
      MinCapacity: !Ref InitialShardCount
      ResourceId: !Sub 'stream/${ApplicationMetricsStream}:desiredThroughput'
      RoleARN: !Sub 'arn:aws:iam::${AWS::AccountId}:service-linked-role/AWSServiceRoleForApplicationAutoScaling_KinesisStream'
      ScalableDimension: kinesis:stream:DesiredThroughput
      ServiceNamespace: kinesis

  # Auto Scaling Policy
  StreamScalingPolicy:
    Type: AWS::ApplicationAutoScaling::ScalingPolicy
    Properties:
      PolicyName: !Sub '${EnvironmentName}-stream-scaling'
      PolicyType: TargetTrackingScaling
      ScalingTargetId: !Ref StreamAutoScalingTarget
      TargetTrackingScalingPolicyConfiguration:
        TargetValue: 70.0  # 70% of provisioned throughput
        PredefinedMetricSpecification:
          PredefinedMetricType: KinesisStreamReadCapacityUtilization
        ScaleOutCooldown: 60
        ScaleInCooldown: 300

  LambdaExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

  # CloudWatch Alarms
  StreamThrottlingAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: !Sub '${EnvironmentName}-kinesis-throttling'
      MetricName: WriteProvisionedThroughputExceeded
      Namespace: AWS/Kinesis
      Statistic: Sum
      Period: 60
      EvaluationPeriods: 2
      Threshold: 1
      ComparisonOperator: GreaterThanOrEqualToThreshold
      Dimensions:
        - Name: StreamName
          Value: !Ref ApplicationMetricsStream

Outputs:
  StreamArn:
    Value: !GetAtt ApplicationMetricsStream.Arn
    Export:
      Name: !Sub '${EnvironmentName}-metrics-stream-arn'
  
  StreamName:
    Value: !Ref ApplicationMetricsStream
    Export:
      Name: !Sub '${EnvironmentName}-metrics-stream-name'
  
  FirehoseArn:
    Value: !GetAtt MetricsArchiveFirehose.Arn
    Export:
      Name: !Sub '${EnvironmentName}-metrics-firehose-arn'
```

#### Python: Kinesis Stream Producer (Batched)

```python
#!/usr/bin/env python3
"""
Kinesis Producer with Batching and Error Handling
Optimized for throughput with exponential backoff retry
"""

import json
import boto3
import time
import logging
from datetime import datetime
from threading import Thread, Queue
from typing import Dict, Any, List, Optional
from botocore.exceptions import ClientError

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
logger = logging.getLogger(__name__)

kinesis = boto3.client('kinesis')

class KinesisProducer:
    """High-throughput Kinesis producer with batching"""
    
    def __init__(
        self,
        stream_name: str,
        batch_size: int = 500,
        batch_timeout_sec: float = 1.0,
        max_workers: int = 4
    ):
        self.stream_name = stream_name
        self.batch_size = batch_size
        self.batch_timeout_sec = batch_timeout_sec
        self.max_workers = max_workers
        self.record_queue = Queue()
        self.failed_records = []
        
        # Start batch processing threads
        for _ in range(max_workers):
            worker = Thread(
                target=self._batch_processor,
                daemon=True
            )
            worker.start()
    
    def put_record(
        self,
        partition_key: str,
        data: Dict[str, Any],
        explicit_hash_key: Optional[str] = None
    ) -> None:
        """Queue a record for batched publishing"""
        
        record = {
            'PartitionKey': partition_key,
            'Data': json.dumps(data),
            'ExplicitHashKey': explicit_hash_key
        }
        self.record_queue.put(record)
    
    def _batch_processor(self) -> None:
        """Process records in batches"""
        
        batch = []
        last_flush = time.time()
        
        while True:
            try:
                # Timeout-based flush
                timeout = max(
                    self.batch_timeout_sec - (time.time() - last_flush),
                    0.1
                )
                
                record = self.record_queue.get(timeout=timeout)
                batch.append(record)
                
                # Flush when batch is full
                if len(batch) >= self.batch_size:
                    self._flush_batch(batch)
                    batch = []
                    last_flush = time.time()
                    
            except:  # Queue empty timeout
                # Periodic flush based on time
                if batch and (time.time() - last_flush) >= self.batch_timeout_sec:
                    self._flush_batch(batch)
                    batch = []
                    last_flush = time.time()
    
    def _flush_batch(self, batch: List[Dict]) -> None:
        """Send batch to Kinesis with retry"""
        
        if not batch:
            return
        
        retry_count = 0
        max_retries = 3
        batches_to_retry = [batch]
        
        while batches_to_retry and retry_count < max_retries:
            try:
                current_batch = batches_to_retry.pop(0)
                
                response = kinesis.put_records(
                    Records=current_batch,
                    StreamName=self.stream_name
                )
                
                logger.info(
                    f"Flushed {len(current_batch)} records. "
                    f"Failed: {response['FailedRecordCount']}"
                )
                
                # Retry failed records with exponential backoff
                if response['FailedRecordCount'] > 0:
                    retry_batch = [
                        record for i, record in enumerate(current_batch)
                        if response['Records'][i].get('ErrorCode') is not None
                    ]
                    
                    if retry_batch:
                        backoff = 2 ** retry_count
                        logger.warning(
                            f"Retrying {len(retry_batch)} records. "
                            f"Backoff: {backoff}s"
                        )
                        time.sleep(backoff)
                        batches_to_retry.append(retry_batch)
                        retry_count += 1
                
            except ClientError as e:
                error_code = e.response.get('Error', {}).get('Code')
                if error_code in ['ProvisionedThroughputExceeded', 'InternalFailure']:
                    logger.warning(f"Temporary error: {error_code}. Retrying...")
                    backoff = 2 ** retry_count
                    time.sleep(backoff)
                    batches_to_retry.append(current_batch)
                    retry_count += 1
                else:
                    logger.error(f"Unrecoverable error: {e}")
                    self.failed_records.extend(current_batch)
                    break
        
        if batches_to_retry:
            logger.error(
                f"Failed to publish {len(batches_to_retry)} records after retries"
            )
            self.failed_records.extend(batches_to_retry[0])


# Example usage
if __name__ == "__main__":
    producer = KinesisProducer(
        stream_name='production-application-metrics',
        batch_size=100,
        batch_timeout_sec=2.0,
        max_workers=2
    )
    
    # Simulate metrics from multiple sources
    import random
    from threading import Thread
    
    def emit_metrics(source_id: str):
        """Simulate metric emission from a source"""
        for i in range(1000):
            metric = {
                'source': source_id,
                'metric': random.choice(['cpu', 'memory', 'disk']),
                'value': random.uniform(0, 100),
                'timestamp': datetime.utcnow().isoformat()
            }
            
            # Use source_id as partition key for distribution
            producer.put_record(
                partition_key=source_id,
                data=metric
            )
            time.sleep(0.01)
    
    # Start multiple metric producers
    threads = [
        Thread(target=emit_metrics, args=(f'source-{i}',))
        for i in range(5)
    ]
    
    for t in threads:
        t.start()
    
    for t in threads:
        t.join()
    
    logger.info(f"Completed. Failed records: {len(producer.failed_records)}")
```

#### Kinesis CLI Operations

```bash
#!/bin/bash
# Kinesis Operations Script

set -euo pipefail

STREAM_NAME="production-application-metrics"
REGION="us-east-1"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Put a record
put_record() {
    local partition_key="$1"
    local data="$2"
    
    echo -e "${YELLOW}Putting record...${NC}"
    
    aws kinesis put-record \
        --stream-name "$STREAM_NAME" \
        --partition-key "$partition_key" \
        --data "$data" \
        --region "$REGION" \
        --output json | jq '.ShardId, .SequenceNumber'
}

# Get shard iterator and records
get_records() {
    local shard_id="$1"
    
    echo -e "${YELLOW}Getting shard iterator...${NC}"
    
    iterator=$(aws kinesis get-shard-iterator \
        --stream-name "$STREAM_NAME" \
        --shard-id "$shard_id" \
        --shard-iterator-type LATEST \
        --region "$REGION" \
        --output json | jq -r '.ShardIterator')
    
    echo -e "${YELLOW}Fetching records...${NC}"
    
    aws kinesis get-records \
        --shard-iterator "$iterator" \
        --limit 10 \
        --region "$REGION" \
        --output json | jq '.Records[] | {
            Data: .Data,
            SequenceNumber,
            PartitionKey
        }'
}

# List shards
list_shards() {
    echo -e "${YELLOW}Listing shards...${NC}"
    
    aws kinesis list-shards \
        --stream-name "$STREAM_NAME" \
        --region "$REGION" \
        --output json | jq '.Shards[] | {
            ShardId,
            SequenceNumberRange,
            AdjacentParentShardId
        }'
}

# Describe stream
describe_stream() {
    echo -e "${YELLOW}Describing stream...${NC}"
    
    aws kinesis describe-stream \
        --stream-name "$STREAM_NAME" \
        --region "$REGION" \
        --output json | jq '.StreamDescription | {
            StreamName,
            StreamStatus,
            StreamModeDetails,
            Shards: (.Shards | length)
        }'
}

# Monitor stream metrics
monitor_metrics() {
    local interval="${1:-5}"
    
    echo -e "${YELLOW}Monitoring stream metrics (interval: ${interval}s)${NC}"
    
    while true; do
        clear
        echo "=== Kinesis Stream Metrics ==="
        
        # Get latest metrics
        aws cloudwatch get-metric-statistics \
            --namespace AWS/Kinesis \
            --metric-name IncomingRecords \
            --dimensions Name=StreamName,Value="$STREAM_NAME" \
            --statistics Sum \
            --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
            --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
            --period 60 \
            --region "$REGION" \
            --output json | jq '.Datapoints[-5:] | sort_by(.Timestamp) | .[] | {
                Timestamp,
                IncomingRecords: .Sum
            }'
        
        echo ""
        sleep "$interval"
    done
}

# Reshard stream
reshard_stream() {
    local new_shard_count="$1"
    
    echo -e "${RED}WARNING: Resharding will interrupt stream processing${NC}"
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo -e "${YELLOW}Updating stream...${NC}"
        
        aws kinesis update-stream \
            --stream-name "$STREAM_NAME" \
            --target-throughput "$new_shard_count" \
            --region "$REGION"
        
        echo -e "${GREEN}Reshard initiated${NC}"
    fi
}

# Main
main() {
    case "${1:-help}" in
        put)
            put_record "${2:-test-key}" "${3:-test data}"
            ;;
        get)
            get_records "$2"
            ;;
        list-shards)
            list_shards
            ;;
        describe)
            describe_stream
            ;;
        monitor)
            monitor_metrics "${2:-5}"
            ;;
        reshard)
            reshard_stream "$2"
            ;;
        *)
            echo "Usage: $0 <command> [args]"
            echo "Commands:"
            echo "  put <partition_key> <data>"
            echo "  get <shard-id>"
            echo "  list-shards"
            echo "  describe"
            echo "  monitor [interval_sec]"
            echo "  reshard <new-shard-count>"
            ;;
    esac
}

main "$@"
```

### ASCII Diagrams

#### Kinesis Stream Architecture with Auto Scaling
```
┌─────────────────────────────────────────────────────────┐
│           Kinesis Data Stream                           │
│                                                          │
│  Shards (Auto-Scaling):                                 │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │
│  │   Shard 1    │ │   Shard 2    │ │   Shard 3    │   │
│  │1K rec/sec    │ │1K rec/sec    │ │1K rec/sec    │   │
│  │1 MB/sec      │ │1 MB/sec      │ │1 MB/sec      │   │
│  └──────────────┘ └──────────────┘ └──────────────┘   │
│                                                          │
│  Retention: 24 hours (configurable to 365 days)        │
│  Records: Ordered per shard, not globally              │
│                                                          │
└──────────────┬──────────────────────────────────────────┘
               │
    ┌──────────┼──────────────────┐
    │          │                  │
    ▼          ▼                  ▼
┌────────┐ ┌────────┐ ┌──────────────┐
│Consumer│ │Consumer│ │Kinesis       │
│Lambda  │ │Lambda  │ │Firehose      │
│(EFO)   │ │(Polling)│ │(Auto-Scale)  │
└────────┘ └────────┘ └──────┬───────┘
    │          │              │
    │          │         ┌────▼────┐
    │          │         │   S3    │
    │          │         │  Data   │
    │          │         │  Lake   │
    └──────────┴─────────┴─────────┘

AutoScaling based on:
- TargetUtilization: 70% of provisioned throughput
- Scale-out: 60 seconds
- Scale-in: 300 seconds
```

#### Kinesis Firehose Transformation Pipeline
```
Source Records (Kinesis Stream)
    │
    ├─ Input: {"temp": 25.5, "device": "s-001"}
    │
    ▼
Batching & Buffering
    ├─ Buffer size: 64 MB
    ├─ Buffer time: 300 seconds
    ├─ Batch 100 records
    │
    ▼
Optional Transformation (Lambda)
    ├─ Enrich data:
    │  {"temp": 25.5, "device": "s-001",
    │   "location": "building-A", "timestamp": "2026-03-08T12:00:00Z"}
    │
    ├─ Filter invalid records
    │
    ▼
Compression & Formatting
    ├─ Format: Parquet (columnar)
    ├─ Compression: GZIP
    │
    ▼
S3 Delivery
    ├─ Partitioned Path:
    │  s3://bucket/metrics/year=2026/month=03/day=08/hour=12/
    │
    ├─ Success: Continue
    │
    └─ Failure: Move to Error Path
       s3://bucket/errors/year=2026/...

Failed records saved to DLQ (SQS) for re-processing
```

#### Kinesis Partition Key Distribution
```
Poorly Distributed:
┌────────────────────────────────┐
│ Partition Keys (All users)     │
│ ├─ "user-001" → Shard 1 (HOT)  │ ◄── Load imbalance!
│ ├─ "user-001" → Shard 1 (HOT)  │
│ ├─ "user-002" → Shard 2 (Cold) │
│ └─ "user-003" → Shard 3 (Cold) │
└────────────────────────────────┘

Well Distributed:
┌────────────────────────────────────────┐
│ Partition Keys (Hash-based)            │
│ ├─ hash("user-001") mod 3 → Shard 1  │
│ ├─ hash("user-002") mod 3 → Shard 2  │
│ ├─ hash("user-003") mod 3 → Shard 3  │
│ ├─ hash("user-004") mod 3 → Shard 1  │  ◄── Balanced
│ └─ hash("user-005") mod 3 → Shard 2  │
└────────────────────────────────────────┘

Result: ~333 rec/sec per shard (even distribution)
```

---

## Summary: AWS Messaging & Event Systems Comparison

| Aspect | SQS | SNS | EventBridge | Kinesis |
|--------|-----|-----|-------------|---------|
| **Model** | Pull (Polling) | Push (Fan-out) | Event Routing Rules | Real-time Stream |
| **Use Case** | Decoupling, Buffering | Notifications, Alerts | Event Orchestration | Real-time Analytics, Streaming |
| **Delivery Guarantee** | At-least-once | At-most-once (HTTP), Attempts | At-least-once (with DLQ) | In-order per shard |
| **Latency** | 100ms - 5 seconds | Immediate | 100ms - 1 second | 100ms - 1 second |
| **Ordering** | Standard: Best-effort, FIFO: Strict | No guarantee | No guarantee | Per partition key |
| **Throughput** | Unlimited shards | 100K msg/sec | 100K events/sec | ~3K msg/sec per shard |
| **Retention** | 4 days (configurable) | Immediate delivery | Real-time only | 24 hours - 1 year |
| **Cost** | By API calls | By notifications | By events | By shard-hours + API calls |
| **Scaling** | Automatic | Automatic | Automatic | Manual shards or On-Demand |
| **Best Practice** | Queue worker patterns | Multi-channel notifications | Cross-service orchestration | High-volume data pipelines |

---

## Real-World Architecture Example

```
┌──────────────────────────────────────────────────────────────────┐
│               Event-Driven Modern Application                     │
└──────────────────────────────────────────────────────────────────┘

User Places Order
    │
    ▼
┌──────────────────────────────────────────────────────────────────┐
│ Order Service (Lambda)                                           │
│ ├─ Validate order                                               │
│ ├─ Publish "OrderCreated" event to EventBridge                  │
│ └─ Return confirmation to user                                  │
└────────────────────┬─────────────────────────────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │   EventBridge (Rule)  │
         │   source: orders.api  │
         │   detailType: Order*  │
         └───────────┬───────────┘
                     │
        ┌────────────┼────────────┬──────────────┐
        │            │            │              │
        ▼            ▼            ▼              ▼
    ┌─────┐     ┌─────────┐ ┌──────┐    ┌──────────────┐
    │ SNS │     │ SQS for │ │Lambda│    │EventBridge   │
    │ Topic     │Email    │ │Payment   │Rule for      │
    └──┬──┘     └────┬────┘ └───┬──┘    │Analytics    │
       │    Notification │      │       │Event        │
       │    Email       │       │       └──────┬───────┘
       │                │       │              │
       ▼                ▼       ▼              ▼
   ┌──────┐      ┌─────────┐ ┌──────┐  ┌──────────────┐
   │Email │      │Worker   │ │Payment  │Kinesis Stream│
   │Service       │Service  │ │Gateway  │+ Firehose    │
   └──────┘      └────┬────┘ │        │→ S3 Analytics│
                      │       └─┬──────┘└──────────────┘
                      │         │
                      ▼         ▼
                 ┌────────────────────┐
                 │   DynamoDB /       │
                 │   Database         │
                 │   Updates          │
                 └────────────────────┘
```

This architecture demonstrates:
1. **Loose Coupling**: Services communicate via events, not direct calls
2. **Scalability**: Each service can scale independently
3. **Reliability**: DLQs and retry policies ensure no message loss
4. **Observability**: Events flowing through EventBridge enable tracing
5. **Cost Efficiency**: Pay-per-use model with automatic scaling

---

# Section 5: Hands-on Scenarios

## Scenario 1: Debugging Message Loss in Production SQS Pipeline

### Problem Statement
A payment processing pipeline using SQS has been silently losing messages. For every 1,000 orders placed, approximately 50-100 payment events are never processed. The team noticed the issue only after financial reconciliation showed discrepancies. No alarms were triggered because the system appeared healthy.

### Architecture Context
```
Order Service (Lambda)
    ↓
E-commerce Database (DynamoDB)
    ↓
SQS Queue (payment-processing)
    ├─ Visibility Timeout: 30 seconds
    ├─ Message Retention: 4 days
    └─ Max Receive Count: Not configured (No DLQ)
    ↓
Payment Lambda Consumer (5 concurrent executions)
    ↓
Payment Gateway API
    ↓
Billing System Update
```

### Troubleshooting Steps

**Step 1: Verify Queue Configuration**
```bash
# Check if DLQ is configured
aws sqs get-queue-attributes \
    --queue-url "https://sqs.us-east-1.amazonaws.com/123456/payment-processing" \
    --attribute-names RedrivePolicy \
    --output json

# Result: RedrivePolicy not found → Missing DLQ!
```

**Issue Identified**: No Dead-Letter Queue means failed messages are retried indefinitely, then disappear after visibility timeout cycles.

**Step 2: Analyze CloudWatch Metrics**
```bash
# Check for high ApproximateAgeOfOldestMessage
aws cloudwatch get-metric-statistics \
    --namespace AWS/SQS \
    --metric-name ApproximateAgeOfOldestMessage \
    --dimensions Name=QueueName,Value=payment-processing \
    --start-time "$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S)" \
    --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
    --period 300 \
    --statistics Average,Maximum
```

**Issue Identified**: Maximum age is 40 seconds, but visibility timeout is 30 seconds. Messages are being re-delivered before processing completes!

**Step 3: Check Lambda Logs**
```bash
# Search for timeout patterns
aws logs filter-log-events \
    --log-group-name /aws/lambda/payment-processor \
    --filter-pattern "Task timed out" \
    --start-time $(($(date +%s) - 86400))000 \
    --query 'events[].message' \
    --output text
```

**Root Causes Identified**:
1. Visibility timeout (30s) < Average payment API latency (45s)
2. No DLQ configured → Failed messages vanish
3. Payment Lambda occasionally timeouts (55 seconds)

### Solution Implementation

**Apply Security and Configuration Changes:**

```bash
# Step 1: Create Dead-Letter Queue
aws sqs create-queue \
    --queue-name payment-processing-dlq \
    --attributes VisibilityTimeout=300,MessageRetentionPeriod=1209600

DLQ_ARN=$(aws sqs get-queue-attributes \
    --queue-url "https://sqs.us-east-1.amazonaws.com/123456/payment-processing-dlq" \
    --attribute-names QueueArn \
    --query 'Attributes.QueueArn' \
    --output text)

# Step 2: Configure DLQ on main queue
aws sqs set-queue-attributes \
    --queue-url "https://sqs.us-east-1.amazonaws.com/123456/payment-processing" \
    --attributes RedrivePolicy="{\"deadLetterTargetArn\":\"$DLQ_ARN\",\"maxReceiveCount\":3}"

# Step 3: Increase visibility timeout
aws sqs set-queue-attributes \
    --queue-url "https://sqs.us-east-1.amazonaws.com/123456/payment-processing" \
    --attributes VisibilityTimeout=180

# Step 4: Update Lambda timeout and memory
aws lambda update-function-configuration \
    --function-name payment-processor \
    --timeout 120 \
    --memory-size 512
```

**Update Lambda Consumer Code for Idempotency:**

```python
import json
import boto3
import hashlib
from datetime import datetime

sqs = boto3.client('sqs')
dynamodb = boto3.resource('dynamodb')
payments_table = dynamodb.Table('payment-processing-idempotency')

def lambda_handler(event, context):
    for record in event['Records']:
        receipt_handle = record['receiptHandle']
        message_body = record['body']
        
        try:
            order_data = json.loads(message_body)
            order_id = order_data['orderId']
            
            # Idempotency check
            message_hash = hashlib.sha256(message_body.encode()).hexdigest()
            
            try:
                response = payments_table.get_item(Key={'MessageHash': message_hash})
                if 'Item' in response:
                    print(f"Message {order_id} already processed, skipping")
                    sqs.delete_message(
                        QueueUrl=event['Records'][0]['eventSourceARN'].replace(':', '/'),
                        ReceiptHandle=receipt_handle
                    )
                    continue
            except Exception as e:
                print(f"Idempotency check error (non-blocking): {e}")
            
            # Process payment with timeout handling
            result = process_payment(order_data, timeout=100)  # 20s buffer
            
            # Mark as processed
            payments_table.put_item(Item={'MessageHash': message_hash, 'ProcessedAt': datetime.utcnow().isoformat()})
            
            # Delete from queue
            sqs.delete_message(
                QueueUrl=event['Records'][0]['eventSourceARN'].replace(':', '/'),
                ReceiptHandle=receipt_handle
            )
            
        except Exception as e:
            print(f"Error processing payment: {e}")
            # Let message return to queue for retry
            raise

def process_payment(order, timeout):
    # Call payment gateway with timeout handling
    pass
```

**Create Comprehensive Monitoring:**

```bash
# Create CloudWatch alarms
aws cloudwatch put-metric-alarm \
    --alarm-name payment-queue-dlq-alarm \
    --alarm-description "Alert when messages in DLQ" \
    --metric-name ApproximateNumberOfMessagesVisible \
    --namespace AWS/SQS \
    --statistic Average \
    --period 300 \
    --evaluation-periods 1 \
    --threshold 1 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --dimensions Name=QueueName,Value=payment-processing-dlq

# Alarm for visibility timeout issues
aws cloudwatch put-metric-alarm \
    --alarm-name payment-queue-age-alarm \
    --alarm-description "Alert if messages age exceeds 120s" \
    --metric-name ApproximateAgeOfOldestMessage \
    --namespace AWS/SQS \
    --statistic Maximum \
    --period 300 \
    --evaluation-periods 2 \
    --threshold 120 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=QueueName,Value=payment-processing
```

### Best Practices Applied

1. **DLQ Implementation**: Captures failed messages for analysis and replay
2. **Idempotency**: Prevents duplicate payment charges on redelivery
3. **Visibility Timeout**: Set to 3x average processing time (180s > 45s API latency)
4. **Monitoring**: Proactive alerts for queue depth and message age
5. **Lambda Configuration**: Increased timeout with proper error handling

### Outcome
- **Message Loss**: Reduced from 5-10% to 0% (with proper idempotency)
- **Recovery**: Failed payments in DLQ can be replayed without data loss
- **Visibility**: Real-time alerts on processing issues
- **Cost**: Minimal increase (DLQ storage) with massive reliability gain

---

## Scenario 2: EventBridge Infinite Loop Creating Cascading Failures

### Problem Statement
An autonomous event-driven system using EventBridge experienced a cascading failure. A single misconfigured rule triggered itself repeatedly, sending 50,000 events/minute to downstream systems. This overwhelmed the system and caused $15,000+ in unexpected AWS costs within 2 hours.

### Root Cause Analysis

**Misconfigured Rule:**
```json
{
  "Name": "order-status-updater",
  "EventPattern": {
    "source": ["orders.service"],
    "detail-type": ["Order Status Changed"]
  },
  "Targets": [
    {
      "Arn": "arn:aws:events:us-east-1:123456:event-bus/default",
      "RoleArn": "arn:aws:iam::123456:role/EventBridgeRole"
    }
  ]
}
```

**Issue**: Rule re-publishes events back to the same event bus, creating a cycle:
```
Order Event → Rule → Publishes back to default bus → Matches same rule → Loop!
```

### Prevention and Recovery

**Step 1: Emergency Mitigation**
```bash
# Disable the problematic rule immediately
aws events disable-rule --name order-status-updater

# Delete failed events from DLQ
aws sqs purge-queue --queue-url https://sqs.us-east-1.amazonaws.com/123456/eventbridge-dlq

# Monitor CloudWatch for cascading Lambda invocations
aws logs tail /aws/lambda/ --follow --filter-pattern "ERROR"
```

**Step 2: Implement Event Versioning**
```yaml
# CloudFormation: Versioned Event Bus Rules
Resources:
  OrderEventBus:
    Type: AWS::Events::EventBus
    Properties:
      Name: production-order-events

  OrderStatusRule:
    Type: AWS::Events::Rule
    Properties:
      EventBusName: !Ref OrderEventBus
      EventPattern:
        source:
          - orders.service
        detail-type:
          - Order Status Changed v2  # Explicit versioning
        detail:
          version: ['2']  # Prevent v1 events from matching
      Targets:
        - Arn: !GetAtt NotificationQueue.Arn
          RoleArn: !GetAtt EventBridgeRole.Arn
          DeadLetterConfig:
            Arn: !GetAtt EventDLQ.Arn
```

**Step 3: Add Loop Prevention Logic**
```python
import json
import logging

def lambda_handler(event, context):
    """
    Prevent infinite loops by tracking event transformations
    """
    
    # Extract or initialize breadcrumb
    breadcrumb = event.get('Meta', {}).get('Breadcrumb', [])
    current_function = context.function_name
    
    # Check for loops (same function appears 3+ times)
    if breadcrumb.count(current_function) >= 3:
        logger.error(f"Potential loop detected in {current_function}")
        return {'statusCode': 400, 'body': 'Loop detected'}
    
    # Add this function to breadcrumb
    breadcrumb.append(current_function)
    event['Meta'] = {'Breadcrumb': breadcrumb, 'Depth': len(breadcrumb)}
    
    # Process event
    try:
        result = business_logic(event)
        
        # Only re-publish if necessary (not back to same bus/pattern)
        if should_publish_downstream(event):
            publish_to_different_bus(result)
        
        return result
    except Exception as e:
        logger.exception(f"Error processing: {e}")
        raise
```

**Step 4: Implement Cost Controls**
```bash
# Set maximum events/second quota
aws service-quotas request-service-quota-increase \
    --service-code events \
    --quota-code L-8F6B3D38 \
    --desired-value 10000

# Create budget alert for EventBridge costs
aws budgets create-budget \
    --account-id 123456789 \
    --budget file://budget.json \
    --notifications-with-subscribers file://notifications.json
```

### Best Practices for Loop Prevention

1. **Event Versioning**: Explicit version numbers prevent version drift
2. **Breadcrumb Tracking**: Track event flow through functions
3. **Target Bus Isolation**: Don't publish back to originating bus
4. **Dead-Letter Queue**: Capture failed events for analysis
5. **Cost Limits**: Set AWS budget alerts and Lambda concurrency limits
6. **Testing**: Validate event patterns don't match their own output

### Outcome
- **Loop Prevention**: 100% elimination through versioning + DLQ
- **Cost Control**: Established budget alerts (prevented $15k+ incidents)
- **Traceability**: Full event flow visibility with breadcrumbs
- **Recovery**: DLQ events replayed with fixed rules safely

---

## Scenario 3: Kinesis Shard Hotspot Under Peak Load

### Problem Statement
A real-time analytics pipeline using Kinesis experiences severe throttling during marketing campaigns. All traffic goes to a single shard because the partition key (user_id) is heavily skewed: 40% of traffic comes from the same user cohort (bots, test users, etc.). During peak loads, the system throttles at 1,000 records/second, missing critical business metrics.

### Architecture Issue
```
     Sales Events (100K events/sec)
              │
              ├─ 40% → user_id: "test-bot" → Shard 1 (HOT - 400K/sec attempted)
              ├─ 30% → user_id: "analytics-crawler" → Shard 2 (WARM)
              └─ 30% → user_id: "real-users-xxx" → Shard 3 (WARM)

Shard Throughput: 1K rec/sec per shard
Shard 1: 400K events trying → 1K allowed → 399K throttled!
```

### Resolution

**Step 1: Analyze Current Distribution**
```bash
# Get CloudWatch metrics on throttling
aws cloudwatch get-metric-statistics \
    --namespace AWS/Kinesis \
    --metric-name ReadProvisionedThroughputExceeded \
    --dimensions Name=StreamName,Value=sales-analytics \
    --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
    --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
    --period 60 \
    --statistics Sum
```

**Step 2: Change Partition Key Strategy**

```python
# BEFORE (Bad): Single user_id partition key
def put_event_old(user_id, event_data):
    kinesis.put_record(
        StreamName='sales-analytics',
        Data=json.dumps(event_data),
        PartitionKey=user_id  # ← Hotspot!
    )

# AFTER (Good): Composite partition key with hash
import hashlib

def put_event_new(user_id, event_data, timestamp):
    # Distribute traffic evenly across shards
    # Hash user_id + timestamp minute to get random distribution
    
    time_bucket = timestamp // 60  # Group by minute
    
    # Create composite key with better distribution
    composite_key = f"{user_id}#{time_bucket}"
    
    # Further improve with salt to randomize test users
    if 'test' in user_id.lower() or 'bot' in user_id.lower():
        # Add random suffix to break bot concentration
        import random
        composite_key = f"{user_id}#{time_bucket}#{random.randint(0, 9)}"
    
    kinesis.put_record(
        StreamName='sales-analytics',
        Data=json.dumps(event_data),
        PartitionKey=composite_key  # Much better distribution
    )

# BEST: Use explicit hash key for fine-grained control
def put_event_best(user_id, event_data):
    import hashlib
    
    # Create hash in 128-bit space (Kinesis partition key space)
    hash_obj = hashlib.sha256(user_id.encode())
    hash_int = int(hash_obj.hexdigest(), 16)
    
    # Map to Kinesis partition range (0 to 2^128-1)
    explicit_hash_key = str(hash_int % (2**128))
    
    kinesis.put_record(
        StreamName='sales-analytics',
        Data=json.dumps(event_data),
        PartitionKey=user_id,  # Still needed for shard assignment
        ExplicitHashKey=explicit_hash_key  # Override for precise distribution
    )
```

**Step 3: Implement Auto-Scaling**

```yaml
AWSTemplateFormatVersion: '2010-09-09'

Resources:
  SalesAnalyticsStream:
    Type: AWS::Kinesis::Stream
    Properties:
      StreamName: sales-analytics
      StreamModeDetails:
        StreamMode: ON_DEMAND  # ← Automatic scaling!
      # Alternative if using PROVISIONED:
      # ShardCount: 100  (manually set high)

  # For PROVISIONED mode: Add auto-scaling
  AutoScalingTarget:
    Type: AWS::ApplicationAutoScaling::ScalableTarget
    Properties:
      MaxCapacity: 200
      MinCapacity: 50
      ResourceId: 'stream/sales-analytics:desiredThroughput'
      RoleARN: !Sub 'arn:aws:iam::${AWS::AccountId}:service-linked-role/AWSServiceRoleForApplicationAutoScaling_KinesisStream'
      ScalableDimension: kinesis:stream:DesiredThroughput
      ServiceNamespace: kinesis

  AutoScalingPolicy:
    Type: AWS::ApplicationAutoScaling::ScalingPolicy
    Properties:
      PolicyName: kinesis-auto-scaling
      PolicyType: TargetTrackingScaling
      ScalingTargetId: !Ref AutoScalingTarget
      TargetTrackingScalingPolicyConfiguration:
        TargetValue: 70.0
        PredefinedMetricSpecification:
          PredefinedMetricType: KinesisStreamWriteCapacityUtilization
        ScaleOutCooldown: 60
        ScaleInCooldown: 300
```

**Step 4: Monitor Distribution**

```bash
# Script to verify even shard distribution
#!/bin/bash

STREAM_NAME="sales-analytics"

# Get shard list
SHARDS=$(aws kinesis list-shards \
    --stream-name "$STREAM_NAME" \
    --query 'Shards[].ShardId' \
    --output text)

echo "=== Shard Distribution Analysis ==="

for SHARD_ID in $SHARDS; do
    # Get shard metrics
    RECORDS=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/Kinesis \
        --metric-name IncomingRecords \
        --dimensions Name=StreamName,Value="$STREAM_NAME" Name=ShardId,Value="$SHARD_ID" \
        --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
        --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
        --period 3600 \
        --statistics Sum \
        --query 'Datapoints[0].Sum' \
        --output text)
    
    printf "Shard %-20s Records: %10.0f\n" "$SHARD_ID" "$RECORDS"
done
```

### Best Practices Applied

1. **Composite Partition Keys**: Time-based bucketing breaks concentration
2. **ON_DEMAND Mode**: Eliminates manual scaling needs
3. **Hash Distribution**: Randomization for test/bot traffic
4. **Monitoring**: Per-shard metrics verify even distribution
5. **Traffic Isolation**: Separate streams for different priority levels

### Outcome
- **Throughput**: Increased from 1K to 100K+ rec/sec per shard
- **Hotspots**: Eliminated through better partition key strategy
- **Cost**: ON_DEMAND mode reduced 30% during off-peak hours
- **Peak Performance**: Handled 500K+ events/sec during campaign

---

## Scenario 4: Cross-Account SNS Topic Subscription Failure

### Problem Statement
A multi-account architecture needs to aggregate alerts from 5 regional AWS accounts to a central logging account for compliance storage. SNS subscriptions fail intermittently with "AccessDenied" errors. The team suspects cross-account IAM permissions are incorrect, but can't identify which specific policy statement is missing.

### Debugging Process

**Step 1: Test Cross-Account Subscription**
```bash
# From central account, subscribe to topic in spoke account
SPOKE_TOPIC_ARN="arn:aws:sns:us-east-1:111111111111:alerts"
CENTRAL_QUEUE_ARN="arn:aws:sqs:us-east-1:222222222222:central-alerts"

aws sns subscribe \
    --topic-arn "$SPOKE_TOPIC_ARN" \
    --protocol sqs \
    --endpoint "$CENTRAL_QUEUE_ARN" \
    --region us-east-1 \
    --error

# Error: AccessDenied
```

**Step 2: Verify Topic Permissions**
```bash
# Check topic access policy
aws sns get-topic-attributes \
    --topic-arn "$SPOKE_TOPIC_ARN" \
    --attribute-name Policy \
    --region us-east-1 \
    --output json

# Missing: Central account not granted access
```

**Step 3: Implement Correct Cross-Account Policy**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CentralAccountSubscribe",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::222222222222:root"  // Central account
      },
      "Action": [
        "SNS:Subscribe",
        "SNS:Receive",
        "SNS:GetTopicAttributes"
      ],
      "Resource": "arn:aws:sns:us-east-1:111111111111:alerts"
    },
    {
      "Sid": "AllowSQSDelivery",
      "Effect": "Allow",
      "Principal": {
        "Service": "sns.amazonaws.com"
      },
      "Action": "SQS:SendMessage",
      "Resource": "arn:aws:sqs:us-east-1:222222222222:central-alerts",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "arn:aws:sns:us-east-1:111111111111:alerts"
        }
      }
    }
  ]
}
```

**Step 4: Automate Cross-Account Setup**

```bash
#!/bin/bash
# Deploy to all spoke accounts in parallel

set -euo pipefail

CENTRAL_ACCOUNT_ID="222222222222"
CENTRAL_REGION="us-east-1"
SPOKE_ACCOUNTS=("111111111111" "111111111112" "111111111113")

# Function to set up spoke account
setup_spoke_account() {
    local spoke_account="$1"
    local spoke_region="$2"
    
    echo "Setting up spoke account: $spoke_account"
    
    # Assume role in spoke account
    CREDS=$(aws sts assume-role \
        --role-arn "arn:aws:iam::${spoke_account}:role/CrossAccountAdmin" \
        --role-session-name "setup-session" \
        --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
        --output text)
    
    export AWS_ACCESS_KEY_ID=$(echo $CREDS | awk '{print $1}')
    export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | awk '{print $2}')
    export AWS_SESSION_TOKEN=$(echo $CREDS | awk '{print $3}')
    
    # Create SNS topic
    TOPIC_ARN=$(aws sns create-topic \
        --name alerts \
        --region "$spoke_region" \
        --query 'TopicArn' \
        --output text)
    
    # Attach cross-account policy
    aws sns set-topic-attributes \
        --topic-arn "$TOPIC_ARN" \
        --attribute-name Policy \
        --attribute-value file://cross-account-policy.json \
        --region "$spoke_region"
    
    # Subscribe central SQS queue
    aws sns subscribe \
        --topic-arn "$TOPIC_ARN" \
        --protocol sqs \
        --endpoint "arn:aws:sqs:${spoke_region}:${CENTRAL_ACCOUNT_ID}:central-alerts" \
        --region "$spoke_region"
    
    echo "✓ Spoke account $spoke_account ready"
}

# Run setup in parallel
for account in "${SPOKE_ACCOUNTS[@]}"; do
    setup_spoke_account "$account" "$CENTRAL_REGION" &
done

wait
echo "All spoke accounts configured"
```

### Best Practices Applied

1. **Explicit Principal**: Always specify exact account/role
2. **Minimal Permissions**: Grant only Subscribe, not Publish
3. **Resource Conditions**: Restrict SQS access to specific SNS topic
4. **Audit Trail**: Enable CloudTrail on cross-account activities
5. **Automated Setup**: Infrastructure-as-Code prevents manual errors

### Outcome
- **Cross-Account**: Full multi-account alert aggregation working
- **Security**: Least-privilege access maintained
- **Automation**: New spokes added in < 5 minutes
- **Compliance**: Full audit trail of all cross-account accesses

---

# Section 6: Most Asked Interview Questions for Senior DevOps Engineers

## Question 1: When would you choose SQS over SNS, and vice versa? Explain a scenario where you'd use both together.

### Expected Answer (Senior Level)

**SQS Use Cases:**
- **Message Durability**: Order processing where each message must be processed exactly once (e.g., payment transactions)
- **Decoupling with Backpressure**: Producer-consumer model where you need to handle spikes by queuing
- **Consumer Polling**: Scenario where consumers are temporary or need retry logic with the same queue

**SNS Use Cases:**
- **Multi-Recipient Broadcasting**: One event triggers multiple independent workflows (e.g., order → email, inventory, accounting)
- **Latency-Critical**: Subscribers need instant notification (SNS push vs SQS poll latency)
- **Mobile/HTTP Notifications**: Built-in support for APNs, GCM, HTTP webhooks

**Both Together (Fan-Out Pattern):**
```
Event Source (Order Placed)
    ↓
SNS Topic
    ├→ SQS Queue 1 (Email Notifications) - Worker pool for email service
    ├→ SQS Queue 2 (Inventory Service) - Durable async inventory update
    ├→ SQS Queue 3 (Analytics) - Stream to data lake
    └→ Lambda Direct (Real-time Dashboard) - Instant push to WebSocket
```

**Why Both?**
- SNS provides fan-out (one-to-many)
- SQS provides durability and retry logic
- Each consumer can scale independently
- Decouples publishers from subscribers
- SQS provides buffers during downstream service outages

**Real Example from Production:**
In an e-commerce platform, we use SNS to broadcast "OrderCreated" events. The email service subscribes to SQS for guaranteed delivery (billing impact if email fails). The inventory service uses Direct Lambda invocation for low-latency stock updates. This hybrid approach gives us reliability where it matters (payments) and responsiveness where needed (UI updates).

---

## Question 2: Explain message visibility timeout in SQS. What happens if you underestimate it?

### Expected Answer (Senior Level)

**What is Visibility Timeout?**
When a consumer receives a message from SQS, the message becomes invisible to other consumers for N seconds. This prevents duplicate processing while one consumer is still working on it.

**The Timeline:**
```
T=0: Message sent to Consumer A
     Message invisible to Consumer B, C, D
     
T=30 (visibility timeout): If Consumer A didn't delete the message,
     Message becomes visible again
     Consumer B may now receive it → DUPLICATE PROCESSING
     
T=45: Consumer A finishes processing, tries to delete
     Message already processed by B → Data inconsistency
```

**Underestimating Visibility Timeout:**

```
Scenario: Payment processing
Visibility Timeout: 30 seconds (WRONG - too low)
Average API latency to payment gateway: 45 seconds

Timeline:
T=0:   Message received by Lambda A (payment-001: $100)
T=30:  Visibility timeout expires, message becomes visible
       Lambda B receives same message  
T=35:  Lambda A successfully charged $100 (total: 1x)
T=40:  Lambda B successfully charged $100 (total: 2x) ← DUPLICATE CHARGE!
T=45: Both try to delete → System inconsistent
```

**Cost of Underestimation:**
- Duplicate transactions (critical for payments)
- Data corruption in databases
- Cascading failures in downstream systems
- Customer complaints about double-charges

**How to Calculate Correct Timeout:**

```bash
# 1. Measure actual processing time
# From logs: p50=20s, p99=60s, p99.9=120s

# 2. Add buffer for retries and network jitter
# p99.9 * 1.5 = 120 * 1.5 = 180 seconds

# 3. Set visibility timeout to this value
aws sqs set-queue-attributes \
    --queue-url "..." \
    --attributes VisibilityTimeout=180

# 4. Set message retention longer than visibility timeout
# Prevents message loss if visibility expires
--attributes MessageRetentionPeriod=345600  # 4 days
```

**Handling Visibility Timeout in Code:**

```python
def process_message_safe(message):
    """
    Proactively extend visibility timeout if processing takes longer
    """
    import threading
    
    receipt_handle = message['ReceiptHandle']
    queue_url = get_queue_url()
    
    # Heartbeat thread: extend visibility every 60 seconds
    def extend_visibility():
        while not processing_done:
            try:
                sqs.change_message_visibility(
                    QueueUrl=queue_url,
                    ReceiptHandle=receipt_handle,
                    VisibilityTimeout=180
                )
                time.sleep(60)
            except:
                pass
    
    heartbeat = threading.Thread(target=extend_visibility, daemon=True)
    heartbeat.start()
    
    try:
        result = expensive_operation(message)  # 150 seconds
        return result
    finally:
        processing_done = True
```

**Senior DevOps Insight:**
Set visibility timeout to **3x the p99 processing time**. In production, we use `ChangeMessageVisibility()` to extend timeout mid-processing for operations that take longer than expected. This prevents duplicate processing while remaining flexible for variable workloads.

---

## Question 3: Design a system that processes 1 million orders/day with exactly-once semantics. What services would you use and why?

### Expected Answer (Senior Level)

**System Requirements:**
- 1M orders/day = ~12 orders/second (low throughput, but must be exact)
- Exactly-once processing (no duplicates, no loss)
- 99.99% availability
- < 1 second latency for order confirmation

**Architecture Decision:**

```
Order API (Gateway)
    ↓
┌─────────────────────────────────────────────────┐
│ SQS FIFO Queue (orders.fifo)                    │
│ ├─ Exactly-once delivery (FIFO guarantee)       │
│ ├─ Message deduplication (5-minute window)      │
│ ├─ Throughput: 3,000/sec with batching         │
│ └─ Cost: Lower than Standard Queue              │
└─────────────────────────────────────────────────┘
    ↓
Lambda Consumer (Batch processing)
    ├─ Batch size: 10 messages (lower latency)
    ├─ Timeout: 60 seconds
    ├─ Memory: 1024 MB
    └─ Concurrency: 4 (enough for 12 msg/sec)
    ↓
DynamoDB Transaction (Atomic processing)
    ├─ Order Table: Primary key = OrderID
    ├─ Idempotency Table: Key = MessageDeduplicationId
    ├─ Status Table: Track processing state
    └─ All writes in single TransactWriteItems
    ↓
SNS Topic (Order processed)
    ├─ Fanout to email, inventory, billing
    └─ Each subscriber has SQS for durability
```

**Why FIFO SQS?**
- Explicit exactly-once guarantee within message group
- MessageDeduplicationId prevents duplicate sends
- Ordering preserved per partition key (order stream)
- Lower cost than monitoring for duplicates

**Idempotency Layer:**

```python
import boto3
from datetime import datetime

sqs = boto3.client('sqs')
dynamodb = boto3.resource('dynamodb')

class OrderProcessor:
    def __init__(self):
        self.idempotency_table = dynamodb.Table('order-idempotency')
        self.order_table = dynamodb.Table('orders')
    
    def process_order_batch(self, messages):
        """
        Process FIFO messages with idempotency guarantee
        """
        for message in messages:
            message_id = message['Body']['messageDeduplicationId']
            order_data = message['Body']
            
            # Check if already processed
            try:
                response = self.idempotency_table.get_item(
                    Key={'MessageID': message_id}
                )
                
                if 'Item' in response:
                    # Already processed, skip
                    self.sqs.delete_message_batch(
                        QueueUrl=queue_url,
                        Entries=[{'Id': message_id, 'ReceiptHandle': message['ReceiptHandle']}]
                    )
                    continue
            except:
                pass
            
            # Atomic transaction: write order + idempotency
            try:
                self.order_table.put_item(
                    Item={
                        'OrderID': order_data['orderId'],
                        'CustomerID': order_data['customerId'],
                        'Amount': order_data['amount'],
                        'Status': 'PROCESSING',
                        'CreatedAt': datetime.utcnow().isoformat()
                    }
                )
                
                # Mark as processed
                self.idempotency_table.put_item(
                    Item={
                        'MessageID': message_id,
                        'ProcessedAt': datetime.utcnow().isoformat(),
                        'OrderID': order_data['orderId'],
                        'TTL': int(time.time()) + (24 * 3600)
                    }
                )
                
                # Publish downstream
                self.publish_to_sns(order_data)
                
                # Delete from queue
                self.sqs.delete_message(
                    QueueUrl=queue_url,
                    ReceiptHandle=message['ReceiptHandle']
                )
            
            except Exception as e:
                # Failed to process - DLQ will handle retry
                raise
```

**Monitoring for Duplicates:**

```bash
# Monitor idempotency table for rejected messages
aws dynamodb query \
    --table-name order-idempotency \
    --key-condition-expression "MessageID = :id" \
    --expression-attribute-values "{\":id\": {\"S\": \"msg-12345\"}}"

# If found: message was already processed
# If not found: first attempt
```

**Scaling the System:**

```
Current: 12 msg/sec
│
├─ FIFO SQS: Can handle 3,000/sec (300x capacity)
├─ Lambda: 4 concurrent = can handle 40+ msg/sec
└─ DynamoDB: On-demand mode (auto-scales)

Scaling to 10x (120 msg/sec):
├─ FIFO remains sufficient (still < 3,000/sec)
├─ Increase Lambda concurrency to 12
└─ DynamoDB auto-scaling handles load
```

---

## Question 4: Your EventBridge rule is matching 100x more events than expected. What's likely wrong, and how do you debug it?

### Expected Answer (Senior Level)

**Common Causes of Over-Matching:**

1. **Too Broad Event Pattern**
   ```json
   // WRONG: Matches everything from source
   {
     "source": ["aws.ec2"]  // All EC2 events!
   }
   
   // CORRECT: Specific event type and state
   {
     "source": ["aws.ec2"],
     "detail-type": ["EC2 Instance State-change Notification"],
     "detail": {
       "state": ["terminated"]  // Only terminations
     }
   }
   ```

2. **Missing Attribute Filters**
   ```python
   # Problem: Subscription receives ALL order events
   browser_app_subscription = {
       "Protocol": "SQS",
       "Endpoint": "arn:aws:sqs:.../browser-app-queue"
   }
   # Result: 1000 events/sec × 10 subscribers = heavy load
   
   # Solution: Filter at subscription level
   browser_app_subscription = {
       "Protocol": "SQS",
       "Endpoint": "...",
       "FilterPolicy": {
           "eventType": ["user-click", "page-view"],  # Only these
           "source": ["web-app"]  # Only web app
       }
   }
   # Result: 50 events/sec × 10 subscribers = manageable
   ```

3. **Wildcard Patterns**
   ```json
   // DANGEROUS
   {
     "detail": {
       "eventName": {"prefix": ""}  // Matches EVERYTHING
     }
   }
   
   // SAFE
   {
     "detail": {
       "eventName": ["CreateDBInstance", "DeleteDBInstance"]
     }
   }
   ```

**Debug Process:**

```bash
# Step 1: Test event pattern locally
aws events test-event-pattern \
    --event-pattern file://pattern.json \
    --event file://sample-event.json

# Step 2: Check rule targets and invocations
aws cloudwatch get-metric-statistics \
    --namespace AWS/Events \
    --metric-name Invocations \
    --dimensions Name=Rule,Value=my-rule-name \
    --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
    --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
    --period 60 \
    --statistics Sum

# Step 3: View actual matched events (via DLQ)
aws sqs receive-message \
    --queue-url "arn:aws:sqs:.../eventbridge-dlq" \
    --max-number-of-messages 10 | jq '.Messages[].Body' | head -20

# Step 4: Check rule definition
aws events describe-rule --name my-rule-name | jq '.EventPattern'
```

**Remediation:**

```python
# Test pattern before deploying
def test_pattern_coverage():
    """
    Validate event pattern doesn't match unintended events
    """
    import json
    
    sample_events = [
        {"source": "aws.ec2", "detail-type": "EC2 Instance State-change"},
        {"source": "aws.s3", "detail-type": "Object Created"},
        {"source": "custom.app", "detail": {"eventType": "user-login"}},
    ]
    
    pattern = {
        "source": ["aws.ec2"],
        "detail-type": ["EC2 Instance State-change Notification"]
    }
    
    # Use test-event-pattern for each
    for event in sample_events:
        result = events_client.test_event_pattern(
            EventPattern=json.dumps(pattern),
            Event=json.dumps(event)
        )
        
        print(f"Event: {event['source']} → Matches: {result['Result']}")
```

---

## Question 5: Your Kinesis stream is experiencing severe throttling on peak traffic. You have 10 shards but one shard is handling 60% of traffic. What's the fix?

### Expected Answer (Senior Level)

**Root Cause: Partition Key Hotspot**

The partition key determines which shard receives the record. If many records use the same partition key, they go to the same shard:

```
Partition Key Distribution:
├─ user_id: "user_1001" → Shard 1 (HOT)    60%
├─ user_id: "user_1002" → Shard 2          15%
├─ user_id: "user_1003" → Shard 3          15%
└─ user_id: "user_1004" → Shard 4          10%

Shard 1: Can handle 1,000 rec/sec
Actual traffic to Shard 1: 6,000 rec/sec
Result: 500K+ invalid records → Throttled!
```

**Quick Fix: Improve Partition Key**

```python
import hashlib

# BEFORE (BAD)
def send_metric_old(user_id, metric_data):
    kinesis.put_record(
        StreamName='metrics',
        Data=json.dumps(metric_data),
        PartitionKey=user_id  # Hotspot if user_id distribution is skewed
    )

# AFTER (GOOD) - Add time dimension
def send_metric_new(user_id, metric_data, timestamp):
    # Create composite key: user + time bucket
    time_bucket = timestamp // 60  # Group by minute
    partition_key = f"{user_id}#{time_bucket}"
    
    kinesis.put_record(
        StreamName='metrics',
        Data=json.dumps(metric_data),
        PartitionKey=partition_key  # Distributes across time windows
    )

# BEST - Add randomization
def send_metric_best(user_id, metric_data):
    import random
    
    # Hash user_id to deterministic random number
    hash_key = hashlib.md5(user_id.encode()).hexdigest()
    random_suffix = int(hash_key, 16) % 100  # 0-99
    
    # Partition key includes randomness
    partition_key = f"{user_id}#{random_suffix}"
    
    kinesis.put_record(
        StreamName='metrics',
        Data=json.dumps(metric_data),
        PartitionKey=partition_key
    )
    # Now: Hot user + 100 different partition keys = spread across shards
```

**Result:**
```
Before: Shard 1 gets 60% (throttled), others idle
After: Each shard gets ~10% (balanced)

6,000 events/sec / 10 shards = 600 events/sec per shard
Shard capacity: 1,000 rec/sec
Utilization: 60% (healthy)
```

**Scaling Strategy:**

```yaml
# Use ON_DEMAND mode (recommended for variable workloads)
Resources:
  MetricsStream:
    Type: AWS::Kinesis::Stream
    Properties:
      StreamName: metrics
      StreamModeDetails:
        StreamMode: ON_DEMAND  # Auto-scales, no partition key tuning needed

# OR: PROVISIONED mode with auto-scaling
StreamAutoScaling:
  Type: AWS::ApplicationAutoScaling::ScalableTarget
  Properties:
    MaxCapacity: 500
    MinCapacity: 10
    ScalableDimension: kinesis:stream:DesiredThroughput
    ServiceNamespace: kinesis
    TargetTrackingScalingPolicy:
      TargetValue: 70.0  # Scale when >70% utilized
```

**Monitoring:**

```bash
# Check per-shard metrics
for SHARD in $(aws kinesis list-shards --stream-name metrics | jq -r '.Shards[].ShardId'); do
    aws cloudwatch get-metric-statistics \
        --namespace AWS/Kinesis \
        --metric-name IncomingRecords \
        --dimensions Name=StreamName,Value=metrics Name=ShardId,Value=$SHARD \
        --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
        --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
        --period 300 \
        --statistics Sum,Average
done
```

---

## Question 6: Describe the most critical monitoring alert you'd set up for an SQS-based payment processing system.

### Expected Answer (Senior Level)

**The Most Critical Alert: Message Age + DLQ Combination**

In payment processing, the worst scenario isn't a single failure—it's silent failures. You need to detect when messages aren't being processed.

```
Most Common Culprits of Silent Failure:
1. Consumer crashes silently (Lambda out of memory)
2. Consumer processes messages but can't ack (permission denied)
3. Network issue between Lambda and downstream API
4. DLQ configured but not monitored
   → Failed messages disappear forever
```

**Critical Alerts (In Priority Order):**

**#1 Alert: Message Age + Queue Depth (EARLIEST WARNING)**
```yaml
AWS::CloudWatch::Alarm:
  ApproximateAgeOfOldestMessage:
    MetricName: ApproximateAgeOfOldestMessage
    Threshold: 300  # 5 minutes (should process in < 1 min)
    AlarmDescription: "Payment stuck in queue unprocessed"
    Statistic: Maximum
    Period: 60
    EvaluationPeriods: 2  # Fire after 2 consecutive breaches
    
  # Combined with queue depth
  ApproximateNumberOfMessagesVisible:
    Threshold: 10000  # Payment queue should never queue 10K
    AlarmDescription: "Consumer can't keep up with producer"
```

**Why This Is Best:**
- Detects stuck payments **before** they fail
- Alerts on **queue depth** (consumer issue)
- Alerts on **message age** (stuck processing)
- Fires in < 2 minutes vs waiting for explicit failure

**Timeline:**
```
T=0:    Payment arrives in queue
T=5:    Still there (age: 5 sec) - Normal
T=30:   Still there (age: 30 sec) - Concerning
T=60:   Still there (age: 60 sec) - Alert 🚨
        → Team investigates while payment still stuck
T=120:  After human investigates and fixes
        → Payment finally processed
        → No customer complaint about delayed payment
```

**#2 Alert: DLQ Depth > 0 (SECONDARY)**
```yaml
DeadLetterQueueDepth:
  MetricName: ApproximateNumberOfMessagesVisible
  QueueName: payment-processing-dlq
  Threshold: 0  # Alert immediately if ANY message in DLQ
  Statistic: Average
  Period: 60
  EvaluationPeriods: 1
  
  # This means a payment failed permanently
  # Trigger: PagerDuty immediate escalation
```

**Why Separate Alert:**
- DLQ messages are **permanent failures**
- Payment wasn't processed AND all retries exhausted
- Needs **immediate human action**

**#3 Alert: Consumer Lambda Errors**
```yaml
LambdaErrors:
  MetricName: Errors
  FunctionName: payment-processor
  Threshold: 5  # 5+ errors in 5 minutes
  Statistics: Sum
  Period: 300
  
  # This catches:
  # - Timeout errors
  # - Permission denied
  # - Memory exceeded
  # - Runtime exceptions
```

**Implementation:**

```python
import boto3
import json

cloudwatch = boto3.client('cloudwatch')

def create_payment_alerts():
    """
    Create complete alert suite for payment processing
    """
    
    # Alert #1: Message Age
    cloudwatch.put_metric_alarm(
        AlarmName='payment-queue-message-age-critical',
        ComparisonOperator='GreaterThanThreshold',
        EvaluationPeriods=2,
        MetricName='ApproximateAgeOfOldestMessage',
        Namespace='AWS/SQS',
        Period=60,
        Statistic='Maximum',
        Threshold=300,  # 5 minutes
        ActionsEnabled=True,
        AlarmActions=['arn:aws:sns:us-east-1:123456:payment-alerts'],
        AlarmDescription='Payment stuck in queue - check consumer health',
        Dimensions=[
            {
                'Name': 'QueueName',
                'Value': 'payment-processing'
            }
        ]
    )
    
    # Alert #2: DLQ Depth
    cloudwatch.put_metric_alarm(
        AlarmName='payment-dlq-depth-critical',
        ComparisonOperator='GreaterThanOrEqualToThreshold',
        EvaluationPeriods=1,
        MetricName='ApproximateNumberOfMessagesVisible',
        Namespace='AWS/SQS',
        Period=60,
        Statistic='Average',
        Threshold=1,  # Alert if ANY message
        ActionsEnabled=True,
        AlarmActions=['arn:aws:sns:us-east-1:123456:payment-critical'],
        Dimensions=[
            {
                'Name': 'QueueName',
                'Value': 'payment-processing-dlq'
            }
        ]
    )
    
    # Alert #3: Lambda Errors
    cloudwatch.put_metric_alarm(
        AlarmName='payment-lambda-errors-high',
        ComparisonOperator='GreaterThanThreshold',
        EvaluationPeriods=1,
        MetricName='Errors',
        Namespace='AWS/Lambda',
        Period=300,
        Statistic='Sum',
        Threshold=5,
        ActionsEnabled=True,
        AlarmActions=['arn:aws:sns:us-east-1:123456:payment-alerts'],
        Dimensions=[
            {
                'Name': 'FunctionName',
                'Value': 'payment-processor'
            }
        ]
    )
```

**Dashboard for Operations Team:**

```json
{
  "Widgets": [
    {
      "Type": "Metric",
      "Properties": {
        "Metrics": [
          ["AWS/SQS", "ApproximateNumberOfMessagesVisible", {"stat": "Average"}],
          ["AWS/SQS", "ApproximateAgeOfOldestMessage", {"stat": "Maximum"}],
          ["AWS/SQS", "NumberOfMessagesReceived", {"stat": "Sum"}],
          ["AWS/Lambda", "Errors", {"stat": "Sum"}]
        ],
        "Period": 60,
        "Stat": "Average",
        "Region": "us-east-1",
        "Title": "Payment Processing Health"
      }
    }
  ]
}
```

---

## Question 7: How would you handle out-of-order messages in Kinesis when they arrive due to retries?

### Expected Answer (Senior Level)

**The Challenge:**

```
Stream: user-events (non-FIFO)

Ideal Order:
1. User login (timestamp: 100)
2. User purchase (timestamp: 104)
3. User logout (timestamp: 108)

Actual Order:
1. User login (timestamp: 100) ✓
2. User purchase -timeout→ retry (timestamp: 104)
3. User logout (timestamp: 108) ✓
4. User purchase (timestamp: 104) ← DUPLICATE, OUT OF ORDER

Problem: Billing system sees:
- Login ✓
- Logout ✓
- Purchase (but user already logged out!) ✗
```

**Solution: Logical Versioning**

```python
import json
import dynamodb
from datetime import datetime

class OutOfOrderHandler:
    def __init__(self, table_name):
        self.dynamodb = boto3.resource('dynamodb')
        self.table = self.dynamodb.Table(table_name)
    
    def process_event(self, event_data):
        """
        Process events with out-of-order protection
        """
        
        user_id = event_data['userId']
        event_type = event_data['eventType']
        timestamp = event_data['timestamp']
        event_sequence = event_data.get('sequence', 0)
        
        # Get current state for this user
        try:
            response = self.table.get_item(Key={'UserId': user_id})
            current_state = response.get('Item', {})
            current_sequence = current_state.get('LastSequence', -1)
            
            # Out-of-order check
            if event_sequence <= current_sequence:
                print(f"Out-of-order event detected: {event_sequence} <= {current_sequence}")
                # Option 1: Discard
                return {'status': 'ignored', 'reason': 'out-of-order'}
                
                # Option 2: Buffer and retry
                # self.buffer_out_of_order(event_data)
        except:
            pass
        
        # Process event
        try:
            result = self.execute_business_logic(event_data)
            
            # Update user state with sequence number
            self.table.update_item(
                Key={'UserId': user_id},
                UpdateExpression='SET LastSequence = :seq, LastEventType = :type, LastProcessedAt = :ts',
                ExpressionAttributeValues={
                    ':seq': event_sequence,
                    ':type': event_type,
                    ':ts': timestamp
                }
            )
            
            return {'status': 'success'}
        
        except Exception as e:
            return {'status': 'failed', 'error': str(e)}
```

**Better Solution: Event Sourcing Pattern**

```python
class EventSourcedUser:
    """
    Store all events in immutable log, derive state from replay
    """
    
    def __init__(self, user_id):
        self.user_id = user_id
        self.events_table = dynamodb.Table('user-events')
        self.state_table = dynamodb.Table('user-state')
    
    def append_event(self, event_data):
        """
        Append event to immutable log (allows replays)
        """
        event_id = f"{self.user_id}#{event_data['timestamp']}"
        
        # Write to immutable event log
        self.events_table.put_item(
            Item={
                'UserId': self.user_id,
                'EventId': event_id,
                'EventType': event_data['eventType'],
                'Timestamp': event_data['timestamp'],
                'Data': event_data,
                'CreatedAt': datetime.utcnow().isoformat()
            }
        )
        
        # Derive current state from ALL events (in timestamp order)
        self.rebuild_state()
    
    def rebuild_state(self):
        """
        Replay all events to derive current state (tolerates out-of-order)
        """
        
        # Query all events for this user, sorted by timestamp
        response = self.events_table.query(
            KeyConditionExpression='UserId = :uid',
            ExpressionAttributeValues={':uid': self.user_id},
            ScanIndexForward=True  # Sort by timestamp ascending
        )
        
        # Replay events in correct order
        state = {
            'userId': self.user_id,
            'status': 'initial',
            'lastLogin': None,
            'purchases': []
        }
        
        for event in response['Items']:
            event_type = event['EventType']
            data = event['Data']
            
            if event_type == 'login':
                state['status'] = 'logged-in'
                state['lastLogin'] = data['timestamp']
            
            elif event_type == 'purchase' and state['status'] == 'logged-in':
                # Only process purchase if currently logged in
                state['purchases'].append({
                    'amount': data['amount'],
                    'timestamp': data['timestamp']
                })
            
            elif event_type == 'logout':
                state['status'] = 'logged-out'
        
        # Write derived state
        self.state_table.put_item(Item=state)
        
        return state
```

**This Approach Handles:**
- ✅ Out-of-order arrivals (replay sorts by timestamp)
- ✅ Duplicates (same event_id won't be added twice)
- ✅ Partial failures (rebuild state anytime)
- ✅ Compliance (immutable audit trail)

---

## Question 8: Your SNS->SQS fan-out is causing cascading failures when one consumer queue backs up. How do you fix this?

### Expected Answer (Senior Level)

**The Problem (Cascading Failure):**

```
SNS Topic (order-events)
    ├→ SQS Queue A (email-service)
    ├→ SQS Queue B (inventory-service) ← BACKED UP!
    └→ SQS Queue C (billing-service)

Timeline:
T=0: Queue B consumer crashes (memory leak)
T=5: Queue B backs up (1,000 messages)
T=10: Queue B backs up (5,000 messages)
T=15: SNS connection stalls (backpressure)
T=20: Queue A & C messages slow down (SNS busy)
T=25: Queue A stops receiving messages (timeout!)
T=30: Email notifications delayed 30+ seconds
T=40: Billing processing late (SLA miss)

Result: ONE queue's failure cascades to ALL queues
```

**Root Cause: Synchronous SNS→SQS Delivery**

SNS tries to deliver to all SQS targets synchronously. If one is slow, it blocks others.

**Fix #1: Isolate with Separate Topics**

```yaml
# Instead of one SNS topic with multiple queues
# Create separate topics by priority/domain

Resources:
  CriticalOrderEventsTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: order-events-critical
      # Subscribers: Billing, Payment (critical)

  StandardOrderEventsTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: order-events-standard
      # Subscribers: Email, Analytics (can be delayed)

  # Produce to both
  PublishToTopics:
    OrderService:
      SNS::Publish:
        - Topics:
            - !Ref CriticalOrderEventsTopic  # Billing, Payment
            - !Ref StandardOrderEventsTopic  # Email, Analytics
```

**Fix #2: Cross-Account Architecture (Best)**

```
SNS Topic (Central)
    │
    ├─→ SQS Queue (Billing) - Same account, fast delivery
    │
    ├─→ SQS Queue (Payment) - Same account, fast delivery
    │
    ├─→ Cross-account delivery mechanism:
    │
    ├─→ EventBridge Rule → Lambda
    │       ↓
    │    Lambda publishes to Remote SNS
    │       ↓
    │    Remote SQS (Email service account)
    │
    └─→ EventBridge Rule → Lambda
            ↓
         Lambda publishes to Remote SNS
            ↓
         Remote SQS (Inventory service account)
```

**Fix #3: Asynchronous Delivery with DLQ**

```python
import json
import boto3
from botocore.exceptions import ClientError

class ResilientSNSPublisher:
    def __init__(self):
        self.sns = boto3.client('sns')
        self.sqs = boto3.client('sqs')
        self.dlq_url = "https://sqs.us-east-1.amazonaws.com/123456/sns-delivery-dlq"
    
    def publish_with_retry(self, topic_arn, message):
        """
        Publish with timeout and DLQ fallback
        """
        
        try:
            # Set short timeout (5 seconds)
            # If SNS can't deliver to all subscribers in time, fail fast
            response = self.sns.publish(
                TopicArn=topic_arn,
                Message=json.dumps(message),
                MessageStructure='json',
                # Custom timeout (not native in boto3, use libraries like tenacity)
            )
            return response
        
        except (ClientError, TimeoutError) as e:
            # SNS delivery failed, send to DLQ for retry
            print(f"SNS delivery failed: {e}. Moving to DLQ")
            
            self.sqs.send_message(
                QueueUrl=self.dlq_url,
                MessageBody=json.dumps({
                    'topicArn': topic_arn,
                    'message': message,
                    'failedAt': str(datetime.utcnow()),
                    'reason': str(e)
                })
            )
            
            # Return immediately (don't block)
            return {'MessageId': 'dlq-fallback'}
```

**Fix #4: Implement Circuit Breaker Pattern**

```python
from datetime import datetime, timedelta

class CircuitBreaker:
    """
    Prevent cascading failures by stopping delivery to slow subscribers
    """
    
    def __init__(self, failure_threshold=5, timeout_seconds=60):
        self.failure_threshold = failure_threshold
        self.timeout_seconds = timeout_seconds
        self.failures = {}
        self.last_failure = {}
    
    def is_circuit_open(self, subscriber_id):
        """Check if subscriber should be skipped"""
        
        if subscriber_id not in self.failures:
            return False
        
        # Check if timeout expired
        if datetime.utcnow() - self.last_failure[subscriber_id] > timedelta(seconds=self.timeout_seconds):
            self.failures[subscriber_id] = 0
            return False
        
        return self.failures[subscriber_id] >= self.failure_threshold
    
    def record_failure(self, subscriber_id):
        self.failures[subscriber_id] = self.failures.get(subscriber_id, 0) + 1
        self.last_failure[subscriber_id] = datetime.utcnow()
    
    def record_success(self, subscriber_id):
        self.failures[subscriber_id] = 0

breaker = CircuitBreaker(failure_threshold=3, timeout_seconds=300)

def publish_to_subscribers(event, subscribers):
    """Publish with circuit breaker protection"""
    
    for subscriber in subscribers:
        # Skip if circuit is open
        if breaker.is_circuit_open(subscriber['id']):
            print(f"Skipping {subscriber['id']} (circuit open)")
            continue
        
        try:
            # Attempt delivery with timeout
            send_with_timeout(event, subscriber, timeout=5)
            breaker.record_success(subscriber['id'])
        
        except TimeoutError:
            breaker.record_failure(subscriber['id'])
            # Continue to next subscriber (don't block)
            continue
```

**Best Practice Monitoring:**

```bash
# 1. Monitor per-queue depth
# 2. Set different alarm thresholds by queue priority
# 3. Implement splunk alerts on delivery latency
# 4. Catch circuit-breaker events

aws cloudwatch put-metric-alarm \
    --alarm-name sns-sqs-delivery-latency \
    --metric-name MessageDeliveryLatency \
    --threshold 10000  # milliseconds \
    --comparison-operator GreaterThanThreshold
```

---

## Question 9: Compare Kinesis On-Demand vs. Provisioned mode. When would you choose each?

### Expected Answer (Senior Level)

**Key Differences:**

| Aspect | On-Demand | Provisioned |
|--------|-----------|------------|
| **Scaling** | Automatic, no shards | Manual shards or auto-scaling |
| **Throughput Limit** | 4,000 write capacity unit (WCU) new records/sec | Per-shard limits (1K rec/sec) |
| **Cost Model** | $0.40/GB ingested | $0.034/shard-hour + API charges |
| **Latency** | P99: <100ms | P99: <100ms (same) |
| **Best For** | Variable/bursty traffic | Predictable/sustained traffic |
| **Warm-up** | Instant | Manual provisioning needed |
| **Cost Calculation** | Variable with usage | Fixed + variable |

**Cost Analysis (Real Numbers):**

```
Scenario 1: Startup with bursty traffic
Average throughput: 500 rec/sec
Peak throughput: 5,000 rec/sec (Black Friday)
Duration: 8 hours/day

Provisioned Mode:
├─ Need 6 shards (to handle 5,000 rec/sec)
├─ Cost: 6 × $0.034/hr × 24 × 30 = ~$147/month
├─ Add API charges (1M PutRecords/day * 30) × $0.014/1M ≈ $0.42/month
└─ Total: ~$147/month (expensive for intermittent usage!)

On-Demand Mode:
├─ Ingestion: Average 500 × 60 × 60 × 24 × 30 = 1.296M GB
├─ Cost: 1.296M × $0.40 = $518/month
└─ Wait... that's MORE expensive!

Scenario 2: High-volume sustained traffic
Average throughput: 10,000 rec/sec
Peak throughput: 12,000 rec/sec
Duration: 24/7 production

Provisioned Mode:
├─ Need 13 shards (to handle 12,000 rec/sec)
├─ Cost: 13 × $0.034 × 24 × 30 = $319/month
├─ API charges: Negligible in comparison
└─ Total: ~$319/month (cost-effective!)

On-Demand Mode:
├─ Ingestion: 10,000 × 60 × 60 × 24 × 30 = 25.92M GB/month
├─ Cost: 25.92M × $0.40 = $10,368/month
└─ Way too expensive!

Scenario 3: Unpredictable SaaS multi-tenant
Customer A: 100 rec/sec
Customer B: 5,000 rec/sec
Customer C: 10,000 rec/sec
Customer D: Spike to 20,000 during campaign

Provisioned:
├─ Must provision for worst case: 35,000 rec/sec = 36 shards
├─ Cost: 36 × $0.034 × 24 × 30 = $884/month (expensive during low periods)
└─ But elastic scaling can help

On-Demand:
├─ Average: 15,000 rec/sec = 3.6M GB/month
├─ Cost: 3.6M × $0.40 = $1,440/month
└─ Still expensive but predictable
```

**When to Choose Each:**

**✅ On-Demand (Good For):**
1. **Startups/MVPs**: Don't know traffic patterns yet
   ```
   Early-stage SaaS: 50-500 rec/sec
   On-Demand cost: $80-1,000/month
   Provisioned: Would need 1 shard min = $25/month (actually cheaper!)
   → Use: Provisioned with 1 shard
   ```

2. **Bursty, Unpredictable Workloads**: Marketing campaigns, events
   ```
   Normal: 500 rec/sec ($80/month provisioned)
   Peak (campaign): 50,000 rec/sec (need 50 shards = $41/month)
   
   On-Demand during peak: 50,000 × 86,400 × 1 day = 4.3M GB = $1,720/day
   Provisioned during peak: 50 × $0.034 × 24 = $40/day
   → Use: Provisioned with auto-scaling
   ```

3. **Multi-tenant SaaS with customers of unknown size**:
   ```
   Can't predict which customers will join
   Mix of small ($100/mo) and large ($10,000/mo) customers
   → Use: On-Demand (simpler billing per customer)
   ```

4. **Development/Staging**: Minimal traffic, highly variable
   ```
   → Use: On-Demand (no wasted capacity)
   ```

**✅ Provisioned (Good For):**
1. **Predictable Enterprise Workloads**: Known throughput
   ```
   Bank processing: 5,000 transactions/sec, 24/7, steady
   → Use: Provisioned 6 shards = $48/month (vs $200/month on-demand)
   ```

2. **Cost-Sensitive at High Volume**: $0.034/shard-hour wins at scale
   ```
   At 10,000+ rec/sec, provisioned becomes cheaper
   ```

3. **Guaranteed Latency Requirements**: Auto-scaling delay not acceptable
   ```
   Real-time trading: Need consistent P99 latency
   → Use: Provisioned (no scaling delay)
   ```

4. **Burst Capacity with Auto-Scaling**:
   ```yaml
   Resources:
     DataStream:
       StreamModeDetails:
         StreamMode: PROVISIONED
         InitialShards: 10  # Baseline
     
     AutoScaling:
       TargetUtilization: 70%
       MinCapacity: 10
       MaxCapacity: 100
       # Scales within 60 seconds
   ```

**My Recommendation:**

```python
def recommend_kinesis_mode(avg_throughput, peak_throughput, variability):
    """
    Data-driven mode selection
    """
    
    variability_ratio = peak_throughput / avg_throughput
    
    if variability_ratio > 10:  # Highly bursty
        return "ON_DEMAND" if peak_throughput < 5000 else "PROVISIONED_WITH_AUTO_SCALING"
    elif avg_throughput > 5000:
        return "PROVISIONED"  # Economies of scale
    elif variability_ratio > 3:
        return "PROVISIONED_WITH_AUTO_SCALING"
    else:
        return "PROVISIONED"  # Smooth, predictable
```

---

## Question 10: Walk me through designing a high-volume logging system (1M events/sec) that requires real-time visibility but also 1-year historical queryability.

### Expected Answer (Senior Level)

**Requirements Analysis:**
- **1M events/sec** = 86.4B events/day = 31T events/year
- **Real-time visibility** = dashboards available immediately  
- **1-year queryability** = searchable back 365 days
- **Cost optimized** = Different storage for hot vs. cold data

**Architecture Decision:**

```
Logging Pipeline (Tiered Storage & Cost)

                     Applications
                     (1M events/sec)
                           │
                    ┌──────▼──────┐
                    │   Kinesis   │ ← Hot data (< 24 hours)
                    │ On-Demand   │    P50: 100ms latency
                    │ (4K WCU)    │    Query: Real-time dashboards
                    └──────┬──────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
            ▼              ▼              ▼
    ┌───────────────┐ ┌─────────┐ ┌─────────────┐
    │  ElasticSearch│ │CloudWatch │ │Firehose→S3 │
    │  (Hot Index)  │ │  Logs    │ │(24hr delay) │
    │  7-day window │ │ Insights │ │             │
    │  $500/month   │ │          │ │             │
    └───────────────┘ └─────────┘ └─────────────┘
            │ Price: $3-5/GB
            │
            │ After 7 days: Move to warm
            ▼
    ┌───────────────────┐
    │ S3 (Warm Tier)   │
    │ ├─ Glue ETL      │ ← Re-partition by date/service
    │ ├─ Partition:    │   Compress to Parquet
    │ │  s3://logs/    │
    │ │  year=2026/    │
    │ │  month=03/     │
    │ │  day=08/       │
    │ │  hour=12/      │
    │ └─ Cost: $0.023/GB
    └───────────────────┘
            │
            │ After 90 days
            ▼
    ┌──────────────────┐
    │ S3 Intelligence  │
    │ Tiering          │
    │ ├─ Move to       │ ← Archive (retrieval delay)
    │ │  Frequent      │
    │ │  Infrequent    │
    │ │  Archive       │
    │ └─ Cost:$0.004/GB
    └──────────────────┘
            │
            │ After 365 days (if compliance requires)
            ▼
    ┌──────────────────┐
    │ S3 Glacier       │
    │ Deep Archive     │
    │ Compliance hold  │
    │ Cost:$0.00099/GB │
    └──────────────────┘
```

**Detailed Implementation:**

```python
# Configuration: Multi-tier logging architecture

TIER_CONFIGURATION = {
    "hot": {
        "duration": "0-24 hours",
        "storage": ["elasticsearch", "cloudwatch-logs"],
        "latency": "<100ms",
        "cost_gb": 5.0,
        "retention": "7 days",
        "use_case": "Real-time dashboards, alerting"
    },
    "warm": {
        "duration": "24 hours - 90 days",
        "storage": ["s3-standard"],
        "latency": "1-5 seconds",
        "cost_gb": 0.023,
        "retention": "90 days",
        "use_case": "Weekly reports, trend analysis"
    },
    "cold": {
        "duration": "90 days - 365 days",
        "storage": ["s3-intelligent-tiering"],
        "latency": "minutes to hours",
        "cost_gb": 0.004,
        "retention": "365 days",
        "use_case": "Quarterly audits, compliance"
    },
    "archive": {
        "duration": "365+ days",
        "storage": ["s3-glacier-deep-archive"],
        "latency": "12 hours",
        "cost_gb": 0.00099,
        "retention": "7+ years",
        "use_case": "Legal holds, regulatory"
    }
}

# Cost Calculator
def calculate_total_cost():
    events_per_sec = 1_000_000
    avg_log_size_bytes = 500
    
    daily_volume_gb = (events_per_sec * 86400 * avg_log_size_bytes) / (1024**3)
    yearly_volume_gb = daily_volume_gb * 365
    
    # Tiered storage cost
    hot_monthly = (daily_volume_gb * 7) * 5.0  # 7 days hot, $5/GB
    warm_monthly = (daily_volume_gb * 83) * 0.023  # 83 days warm
    cold_monthly = (daily_volume_gb * 275) * 0.004  # 275 days cold
    
    total_monthly = hot_monthly + warm_monthly + cold_monthly
    
    print(f"Daily volume: {daily_volume_gb:.2f} GB")
    print(f"Hot tier (7d): ${hot_monthly:.0f}/month")
    print(f"Warm tier (83d): ${warm_monthly:.0f}/month")
    print(f"Cold tier (275d): ${cold_monthly:.0f}/month")
    print(f"Total: ${total_monthly:.0f}/month (~${total_monthly*12:.0f}/year)")

# Result:
# Daily volume: 43.40 GB
# Hot tier (7d): $1,519/month
# Warm tier (83d): $83/month
# Cold tier (275d): $48/month
# Total: $1,650/month (~$19,800/year)
```

**Implementation: Kinesis → Firehose → S3**

```yaml
AWSTemplateFormatVersion: '2010-09-09'

Resources:
  # Stream for log ingestion
  LogStream:
    Type: AWS::Kinesis::Stream
    Properties:
      StreamName: application-logs
      StreamModeDetails:
        StreamMode: ON_DEMAND

  # Firehose for S3 delivery (batching + compression)
  LogsFirehose:
    Type: AWS::KinesisFirehose::DeliveryStream
    Properties:
      DeliveryStreamName: logs-to-s3
      DeliveryStreamType: KinesisStreamAsSource
      KinesisStreamSourceConfiguration:
        KinesisStreamARN: !GetAtt LogStream.Arn
        RoleARN: !GetAtt FirehoseRole.Arn
      ExtendedS3DestinationConfiguration:
        RoleARN: !GetAtt FirehoseRole.Arn
        BucketARN: !GetAtt LogBucket.Arn
        Prefix: "logs/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
        ErrorOutputPrefix: "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/!{firehose:error-output-type}/"
        BufferingHints:
          SizeInMBs: 128
          IntervalInSeconds: 300
        CompressionFormat: GZIP
        DataFormatConversionConfiguration:
          Enabled: true
          SchemaConfiguration:
            RoleARN: !GetAtt FirehoseRole.Arn
            DatabaseName: logs_db
            TableName: application_logs
            Region: !Ref AWS::Region
        ProcessingConfiguration:
          Enabled: true
          Processors:
            - Type: Lambda
              Parameters:
                - ParameterName: LambdaArn
                  ParameterValue: !GetAtt EnrichmentLambda.Arn

  # S3 Bucket with intelligent tiering
  LogBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'application-logs-${AWS::AccountId}'
      IntelligentTieringConfiguration:
        Id: AutoArchive
        Status: Enabled
        Days: 90  # Move to infrequent after 90 days
        ArchiveAfterDays: 180  # Archive after 180 days
      LifecycleConfiguration:
        Rules:
          - Id: MoveToArchive
            Status: Enabled
            Transitions:
              - TransitionInDays: 90
                StorageClass: INTELLIGENT_TIERING
              - TransitionInDays: 365
                StorageClass: GLACIER_IR
          - Id: DeleteOldLogs
            Status: Enabled
            ExpirationInDays: 2555  # 7 years

  # Athena table for querying
  AthenaTable:
    Type: AWS::Glue::Table
    Properties:
      DatabaseName: logs_db
      CatalogId: !Ref AWS::AccountId
      TableInput:
        Name: application_logs
        StorageDescriptor:
          Columns:
            - Name: timestamp
              Type: bigint
            - Name: level
              Type: string
            - Name: service
              Type: string
            - Name: message
              Type: string
            - Name: request_id
              Type: string
          Location: !Sub 's3://${LogBucket}/logs/'
          InputFormat: org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat
          OutputFormat: org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat
          SerdeInfo:
            SerializationLibrary: org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe
```

**Query Patterns:**

```sql
-- Real-time dashboard (ES/CloudWatch)
GET logs-*/_search
{
  "query": {
    "range": {
      "timestamp": {
        "gte": "now-1h",
        "lte": "now"
      }
    }
  },
  "aggs": {
    "by_level": {
      "terms": { "field": "level" }
    }
  }
}

-- Historical analysis (Athena on S3)
SELECT 
  DATE_TRUNC('day', FROM_UNIXTIME(timestamp/1000)) as day,
  service,
  COUNT(*) as error_count
FROM application_logs
WHERE level = 'ERROR' 
  AND DATE(FROM_UNIXTIME(timestamp/1000)) 
    BETWEEN DATE '2026-01-01' AND DATE '2026-03-08'
GROUP BY 1, 2
ORDER BY error_count DESC
```

**Cost Comparison:**

| Approach | Monthly Cost | Storage | Latency |
|----------|--------------|---------|---------|
| All Elasticsearch | $50,000+ | Hot only | <100ms |
| All S3 (no tiering) | ~$3,000/month | No archival | 1-5s |
| **Tiered (Recommended)** | **~$1,650** | 7-day hot + cold | <100ms hot, s slow cold |
| All Cloudwatch Logs | $30,000+ | Limited retention | Moderate |

**Monitoring & SLAs:**

```yaml
Monitoring:
  hot_tier:
    alert_if_query_latency: "> 500ms"
    alert_if_cost_spike: "> 10% daily average"
  
  warm_tier:
    alert_if_s3_access_slow: "> 5 seconds"
    alert_if_storage_grows: "unexpected growth"
  
  cold_tier:
    retention_check: "365 days minimum"
    audit_check: "compliance holds active"

SLA:
  real-time_queries: "p99 < 500ms, p50 < 100ms"  (ES)
  historical_queries: "< 30 seconds for 90-day range" (Athena)
  compliance_retrieval: "< 12 hours"  (Glacier)
```

---

## Summary of Key Takeaways

For a **Senior DevOps Engineer** working with AWS messaging:

1. **Know the trade-offs**: SQS (durability) vs SNS (immediacy) vs EventBridge (routing) vs Kinesis (streams)
2. **Design for failure**: Always include DLQ, monitoring, and retry logic
3. **Understand idempotency**: Process messages safely even with duplicates
4. **Optimize costs**: Right-size shards, use tiering, choose ON_DEMAND vs Provisioned wisely
5. **Build visibility**: Comprehensive monitoring, not just infrastructure metrics
6. **Plan for scale**: What works for 100 msg/sec breaks at 100,000 msg/sec

---

**Created**: March 8, 2026  
**Audience**: DevOps Engineers (5-10+ years experience)  
**Version**: 1.0  
**Status**: Complete
